
#fix the seed
# Random.seed!(1)

if nprocs() <= 2
    p = addprocs(2, topology=:master_worker)
end
@everywhere using DistributedArrays
@everywhere using GigaSOM
@everywhere using Distances
@everywhere using NearestNeighbors

# only use lineageMarkers for clustering
cc = map(Symbol, lineageMarkers)
dfSom = daf.fcstable[:,cc]

som2 = initGigaSOM(dfSom, 10, 10)
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)

winners = mapToGigaSOM(som2, dfSom)

rmprocs(workers())

# extract the codes for consensus clustering
codes = som2.codes
include(homedir()*"/work/GigaSOM.jl/src/io/cCluster.jl")
# retrive the cluster ids
mc =  cc_plus(codes)

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

CSV.write("fedl1_smaller_update_med.csv", expr_median)
CSV.write("feld1_r1_med_norm.csv", expr_med_norm)
# sampleId = daf.fcstable[ : , :sample_id]

cc_tbl = DataFrame(id = cell_clustering)
CSV.write("feld1_smaller_update_clustering.csv", cc_tbl)
