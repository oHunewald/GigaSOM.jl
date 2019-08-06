
#fix the seed
Random.seed!(1)

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

include("../src/io/cCluster.jl")
# retrive the cluster ids
mc =  cc_plus(codes)

cell_clustering = mc[winners.index]

insertcols!(dfSom, 23, cc=cell_clustering)

using Statistics
# median expression values per som node
expr_median = aggregate(dfSom, [:cc], median)


sampleId = daf.fcstable[ : , :sample_id]


# dfCodes = DataFrame(codes)
# names!(dfCodes, Symbol.(som2.colNames))
# CSV.write("parallelDfCodes.csv", dfCodes)
# CSV.write("parallelWinners.csv", winners)
