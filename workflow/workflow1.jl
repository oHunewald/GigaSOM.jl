using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed, SHA, JSON

checkDir()
#create genData and data folder and change dir to dataPath
cwd = pwd()

# datapath = "/Users/ohunewald/work/data_felD1"
# datapath = "/Users/ohunewald/work/SysTact/test_metadata"
# datapath = "/Users/ohunewald/work/SysTact/pre_data/SYSTACT_555_CD3pos"
# datapath = "/home/users/ohunewald/systact/test_metadata"
datapath = "/home/users/ohunewald/systact/data"
# datapath = "/home/users/ohunewald/data"
cd(datapath)
# md = DataFrame(XLSX.readtable("metadata_100.xlsx", "Sheet1", infer_eltypes=true)...)
md = DataFrame(XLSX.readtable("metadata.xlsx", "Sheet1", infer_eltypes=true)...)
# md = DataFrame(XLSX.readtable("metadata_test.xlsx", "Sheet1", infer_eltypes=true)...)
# md = DataFrame(XLSX.readtable("metadata_small.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)

lineageMarkers, functionalMarkers = getMarkers(panel)

fcsRaw = readFlowset(md.file_name)
cleanNames!(fcsRaw)

# create daFrame file
daf = createDaFrame(fcsRaw, md, panel)

cd(cwd)
# using StatsPlots
using Statistics
try
	using StatsBase
catch
	Pkg.add("StatsBase")
end
using StatsBase

try
	using MultivariateStats
catch
	Pkg.add("MultivariateStats")
end

using MultivariateStats

#################################################################
# Export the data for PCA
#################################################################
dfall_median = aggregate(daf.fcstable, :sample_id, Statistics.median)

# get the timepoints for each sample_id
# md.timepoint
md.condition

T = convert(Matrix, dfall_median)
samples_ids = T[:,1]
T_reshaped = permutedims(convert(Matrix{Float64}, T[:, 2:end]), [2, 1])

my_pca = StatsBase.fit(MultivariateStats.PCA, T_reshaped)

yte = MultivariateStats.transform(my_pca,T_reshaped)

df_pca = DataFrame(yte')
df_pca[:sample_id] = samples_ids

# get the condition per sample id and add in DF
v1= df_pca.sample_id; v2=md.sample_id
idxs = indexin(v1, v2)
df_pca[:condition] = md.condition[idxs]
# df_pca[:timepoint] = md.timepoint[idxs]
CSV.write("pca_df.csv", df_pca)

#fix the seed
Random.seed!(1)

p = addprocs(80)

# @everywhere using DistributedArrays
@everywhere using GigaSOM
# @everywhere using Distances
# using Distances

# only use lineageMarkers for clustering
(lineageMarkers,)= getMarkers(panel)
cc = map(Symbol, lineageMarkers)
dfSom = daf.fcstable[:,cc]

som2 = initGigaSOM(dfSom, 10, 10)

# som2 = trainGigaSOM(som2, dfSom, epochs = 1)
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)

winners = mapToGigaSOM(som2, dfSom)

CSV.write("winners.csv", winners)
@time embed = embedGigaSOM(som2, dfSom, k=10, smooth=0.0, adjust=0.5)

CSV.write("embed.csv", DataFrame(embed))

rmprocs(workers())

# extract the codes for consensus clustering
codes = som2.codes
# include("../src/io/cCluster.jl")
# retrive the cluster ids
# mc =  cc_plus(codes)
try
	using RCall
catch
	using Pkg
	Pkg.add("RCall")
end
using RCall
@rlibrary consens2

plot_outdir = "consensus_plots"
nmc = 50
codesT = Matrix(codes')
mc = ConsensusClusterPlus_2(codesT, maxK = nmc, reps = 100,
                           pItem = 0.9, pFeature = 1,
                           clusterAlg = "hc", innerLinkage = "average", finalLinkage = "average",
                           distance = "euclidean", seed = 1234)

cell_clustering = mc[winners.index]

dfSom.cell_clustering = cell_clustering

using Statistics
using LinearAlgebra
# Pkg.add("StatsBase")
using StatsBase
# median expression values per som node
expr_median = aggregate(dfSom, :cell_clustering, median)
# expr_median_norm = deepcopy(expr_median)

# apply uniform scaling to all features (columns)
# get the cell clustering column
cc_aggregated = expr_median.cell_clustering
# remove the cell clustering column
tmp = expr_median[:, filter(x -> x != :cell_clustering, names(expr_median))]
# get the column names
c_names = names(tmp)
tmp_matrix = Matrix(tmp)
dt = fit(UnitRangeTransform, tmp_matrix')
expr_med_norm = StatsBase.transform(dt, tmp_matrix')
expr_med_norm = DataFrame(expr_med_norm')
names!(expr_med_norm, c_names)
# put back the column cell clustering
expr_med_norm[:cell_clustering] = cc_aggregated

CSV.write("expr_median.csv", expr_median)
CSV.write("expr_median_norm.csv", expr_med_norm)
# sampleId = daf.fcstable[ : , :sample_id]

cc_tbl = DataFrame(id = cell_clustering)
CSV.write("cell_clustering.csv", cc_tbl)


cd(cwd)
# # plotting embed in julia
# include(cwd*"/src/visualization/gigasom-fastplots.jl")
#
# cl = winners.index
#
# import NearestNeighbors
#
# points = embed
#
# clpal = clusterPalette(50, alpha=.3)
# colors = vcat([[clpal[c].r clpal[c].g clpal[c].b clpal[c].alpha] for c in cell_clustering]...)
#
# @time img = expand_points(3, rasterize((2048, 2048), points, colors, xlim=(-1.0,24.0),
#                         ylim=(24.0,-1.0)))
#
# Images.save(FileIO.File(FileIO.format"PNG", "test-clusters.png"),
#         Images.colorview(Images.RGBA, img))
#
# expal=expressionPalette(100, alpha=.3)
# nc = daf.fcstable._145Nd_CD69
# nc .-= minimum(nc)
# nc ./= maximum(nc)
# colors = vcat([[expal[c].r expal[c].g expal[c].b expal[c].alpha] for c in Array{Int64,1}(1 .+ trunc.(99*nc))]...)
#
# img = expand_points(3, rasterize((2048, 2048), points, colors, xlim=(-1.0,24.0),
#                 ylim=(24.0,-1.0)))
#
# Images.save(FileIO.File(FileIO.format"PNG", "test-expr.png"),
#         Images.colorview(Images.RGBA, img))
