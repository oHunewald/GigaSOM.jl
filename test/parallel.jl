
#fix the seed
# Random.seed!(1)

if nprocs() <= 2
    p = addprocs(2, topology=:master_worker)
end
@everywhere using DistributedArrays
@everywhere using GigaSOM
@everywhere using Distances

# only use lineageMarkers for clustering
cc = map(Symbol, lineageMarkers)
dfSom = daf.fcstable[:,cc]

som2 = initGigaSOM(dfSom, 10, 10)
som2 = trainGigaSOM(som2, dfSom, epochs = 10)

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
# median expression values per som node
expr_median = aggregate(dfSom, :cell_clustering, median)

CSV.write("expr_med_R10.csv", expr_median)
pwd()
sampleId = daf.fcstable[ : , :sample_id]

cc_tbl = DataFrame(id = cell_clustering)
CSV.write("cell_clustering_R10.csv", cc_tbl)
