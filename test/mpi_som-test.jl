import MPI
using Statistics
using DistributedArrays


function doEpochMPI(ddata)

    # dummy functions
    sumNumerator = zeros(Float64, 100, 10)
    sumDenominator = zeros(Float64, 100)

    return [sumNumerator, sumDenominator]
    # return "this is a result"
end

function trainGigaSOM_mpi(data, epochs)

    #setup
    MPI.Init()
    comm = MPI.COMM_WORLD
    MPI.Barrier(comm)
    commsize = MPI.Comm_size(comm)
    rank = MPI.Comm_rank(comm)

    ddata = distribute(data)
    # result container
    res = [Array{Float64, 2}, Array{Float64, 1}]
    sen = [Array{Float64, 2}, Array{Float64, 1}]

    for j in 1:1

        # dummy functions
        globalSumNumerator = zeros(Float64, 100, 10)
        globalSumDenominator = zeros(Float64, 100)
        # workers code
        if rank > 0
            println("Worker: $rank")
            res = doEpochMPI(localpart(ddata))
            println(res)
            # MPI.Isend(res, 0, rank, comm)
            MPI.Isend(res, 0, rank, comm)
        else # Master
            for node = 1:commsize-1
                ready = false
                ready, junk = MPI.Iprobe(node, node, comm)
                if ready
                    MPI.Recv!(sen, node, node, comm)
                end
            end
        end
        MPI.Barrier(comm)
        MPI.Finalize()
    end

end


function main()

    data = rand(100,40)

    trainGigaSOM_mpi(data, 10)

end

main()
