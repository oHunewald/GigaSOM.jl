using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed

if nprocs() <= 2
    p = addprocs(2, topology=:master_worker)
end
# @everywhere using DistributedArrays
@everywhere using GigaSOM
# @everywhere using Distances

# only use lineageMarkers for clustering

# cc = map(Symbol, lineageMarkers)
# dfSom = daf.fcstable[:,cc]

# som2 = initGigaSOM(dfSom, 10, 10)

datasize = 100_000

trainGigaSOM(datasize, epochs = 1)
@time trainGigaSOM(datasize, epochs = 10)

# winners = mapToGigaSOM(som2, dfSom)

rmprocs(workers())
