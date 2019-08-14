#fix the seed
Random.seed!(1)

if nprocs() <= 2
    p = addprocs(2, topology=:master_worker)
end
@everywhere using DistributedArrays
@everywhere using GigaSOM
@everywhere using Distances

# only use lineageMarkers for clustering

# cc = map(Symbol, lineageMarkers)
# dfSom = daf.fcstable[:,cc]

# som2 = initGigaSOM(dfSom, 10, 10)

som2 = trainGigaSOM(som2, dfSom, epochs = 1)
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)

# winners = mapToGigaSOM(som2, dfSom)

rmprocs(workers())
