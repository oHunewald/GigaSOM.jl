using Distributed
using GigaSOM

nWorkers = 2
addprocs(nWorkers, topology=:master_worker)
@everywhere using GigaSOM

@everywhere function getMatrixFromWorkers()
    a = rand(10,10)
    return a
end

@everywhere function doFuture(x::Future)

    if typeof(x) == Future
        @info "x is future object"
        y=fetch(x)
    else
        @info "x is not a future object"
    end
    println(y)
end

R =  Vector{Any}(undef,nWorkers)

# No fetch
@sync for (idx, pid) in enumerate(workers())
    @async R[idx] = @spawnat pid getMatrixFromWorkers()
end
sizeof(R)
Base.summarysize(R)

@spawnat 2 doFuture(R[1])
