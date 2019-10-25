using GigaSOM, DataFrames, Random, Distributed

Random.seed!(1)

try
    using Distributions
catch
    Pkg.add("Distributions")
end
using Distributions

function printHeader(m, n, g)
    println("-------------------------------------------------")
    println("Data size: $m")
    println("-------------------------------------------------")
    println("Grid Size: $g")
    println("-------------------------------------------------")
    println("Nunber of workers: $n")
    println("-------------------------------------------------")
    println("Timing trainGigaSOM: ")
end

gridsizes = [10, 20]
myworkers = [1,4,20,40,80]
dfSom = rand(50_000_000, 30)

for j in myworkers
    if j > 1
        p = addprocs(j)
    end
    @everywhere using GigaSOM

    som2 = initGigaSOM(dfSom, 10, 10)

    for g in gridsizes
        som2 = initGigaSOM(dfSom, g, g)

        printHeader(size(dfSom), nworkers(), g)
        som2 = trainGigaSOM(som2, DataFrame(dfSom), epochs = 1)
        @time som2 = trainGigaSOM(som2, DataFrame(dfSom), epochs = 10)

        println("Timing embedSOM: ")
        embed = embedGigaSOM(som2, DataFrame(dfSom), k=10, smooth=0.0, adjust=0.5)
        @time embed = embedGigaSOM(som2, DataFrame(dfSom), k=10, smooth=0.0, adjust=0.5)


    end

    if j > 1
        rmprocs(workers())
    end

end
