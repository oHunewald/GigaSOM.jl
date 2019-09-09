using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed, SHA, JSON

checkDir()
#create genData and data folder and change dir to dataPath
cwd = pwd()

# datapath = "/Users/ohunewald/work/SysTact/pre_data/SYSTACT_555_CD3neg"
datapath = "/home/users/ohunewald/systact/pre_data/SYSTACT_555_CD3neg"
cd(datapath)
md = DataFrame(XLSX.readtable("metadata.xlsx", "Sheet1", infer_eltypes=true)...)
# md = DataFrame(XLSX.readtable("metadata.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)

lineageMarkers, functionalMarkers = getMarkers(panel)

fcsRaw = readFlowset(md.file_name)
cleanNames!(fcsRaw)

# create daFrame file
daf = createDaFrame(fcsRaw, md, panel)

cd(cwd)
using StatsPlots
using Statistics
using StatsBase
using MultivariateStats
include("../src/visualization/Plotting.jl")

# some plotting
plotPCA(daf,md)
#fix the seed
Random.seed!(1)

p = addprocs(2)

# @everywhere using DistributedArrays
@everywhere using GigaSOM
# @everywhere using Distances
# using Distances

# only use lineageMarkers for clustering
(lineageMarkers,)= getMarkers(panel)
cc = map(Symbol, lineageMarkers)
dfSom = daf.fcstable[:,cc]

som2 = initGigaSOM(dfSom, 10, 10)
som2 = trainGigaSOM(som2, dfSom, epochs = 10)

winners = mapToGigaSOM(som2, dfSom)

embed = embedGigaSOM(som2, dfSom, k=10, smooth=0.0, adjust=0.5)


rmprocs(workers())

# extract the codes for consensus clustering
codes = som2.codes
# include("../src/io/cCluster.jl")
# retrive the cluster ids
# mc =  cc_plus(codes)
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
