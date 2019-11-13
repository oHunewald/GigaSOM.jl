using GigaSOM, DataFrames, Random, Distributed

p = addprocs(80)

@everywhere using GigaSOM

dfSom = rand(1_000_000_000, 30)

som2 = initGigaSOM(dfSom, 10, 10)

@time som2 = trainGigaSOM(som2, DataFrame(dfSom), epochs = 10)

@time embed = embedGigaSOM(som2, DataFrame(dfSom), k=10, smooth=0.0, adjust=0.5)

rmprocs(workers())


