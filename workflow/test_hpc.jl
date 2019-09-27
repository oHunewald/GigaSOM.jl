using GigaSOM, DataFrames, Random, Distributed

Random.seed!(1)

# ! set the number of workers here:
p = addprocs(2)

@everywhere using GigaSOM

# ! set the size of the Matrix here:
# only change the the first dimension
dfSom = rand(10_000_000, 40)

som2 = initGigaSOM(dfSom, 10, 10)

# precompile
trainGigaSOM(som2, dfSom, epochs = 1)

println("Timing trainGigaSOM: ")
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)

# precompile
embedGigaSOM(som2, dfSom, k=10, smooth=0.0, adjust=0.5)

println("Timing embedGigaSOM: ")
@time embed = embedGigaSOM(som2, dfSom, k=10, smooth=0.0, adjust=0.5)

rmprocs(workers())
