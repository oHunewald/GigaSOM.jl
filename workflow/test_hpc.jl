using GigaSOM, DataFrames, Random, Distributed

p = addprocs(2, topology=:master_worker)
@everywhere using GigaSOM

dfSom = rand(5_000_000, 35)

som2 = initGigaSOM(dfSom, 10, 10)

# precompile
trainGigaSOM(som2, dfSom, epochs = 1)
println("Timing trainGigaSOM: ")
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
rmprocs(workers())


# p = addprocs(20, topology=:master_worker)
# @everywhere using GigaSOM
# som2 = initGigaSOM(dfSom, 10, 10)
# # precompile
# trainGigaSOM(som2, dfSom, epochs = 1)
# println("Timing trainGigaSOM: ")
# @time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
# rmprocs(workers())
#
# p = addprocs(40, topology=:master_worker)
# @everywhere using GigaSOM
# som2 = initGigaSOM(dfSom, 10, 10)
# # precompile
# trainGigaSOM(som2, dfSom, epochs = 1)
# println("Timing trainGigaSOM: ")
# @time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
# rmprocs(workers())
#
# p = addprocs(80, topology=:master_worker)
# @everywhere using GigaSOM
# som2 = initGigaSOM(dfSom, 10, 10)
# # precompile
# trainGigaSOM(som2, dfSom, epochs = 1)
# println("Timing trainGigaSOM: ")
# @time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
# rmprocs(workers())
