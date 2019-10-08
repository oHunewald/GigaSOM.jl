import MPI
using Statistics

function doStuff(x, out_buf)

    for i in x
        # println("Rank: $rank")
        println(i)
        sleep(1)
        # out_buf[i] += 9
    end
end

function main()

    MPI.Init()
    comm = MPI.COMM_WORLD
    size = MPI.Comm_size(comm)
    rank = MPI.Comm_rank(comm)

    data = rand(8)
    println("comm size: $size")

    if rank == 0
        data = ones(8)
    end

    out_buf = zeros(size)

    MPI.Scatter!(data, out_buf, size, 0, comm)
    println("Processor $rank has data: $data")
    tmp=doStuff(data, out_buf)
    # println(tmp)

    MPI.Barrier(comm)
    MPI.Finalize()

end

main()
