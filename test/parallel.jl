
#fix the seed
# Random.seed!(1)

if nprocs() <= 2
    p = addprocs(4, topology=:master_worker)
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
using LinearAlgebra
# median expression values per som node
expr_median = aggregate(dfSom, :cell_clustering, median)
expr_median_norm = deepcopy(expr_median)
# normalize by columns for visualization
for i in 1:size(expr_median, 2)
    expr_median_norm[:, i] = normalize(expr_median[:, i])

end

CSV.write("fedl1_smaller_update_med.csv", expr_median)
# CSV.write("feld1_r1_med_norm", expr_median_norm)
# sampleId = daf.fcstable[ : , :sample_id]

cc_tbl = DataFrame(id = cell_clustering)
CSV.write("feld1_smaller_update_clustering.csv", cc_tbl)
