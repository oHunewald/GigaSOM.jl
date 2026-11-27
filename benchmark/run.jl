# GigaSOM benchmark harness.
#
# Usage (from the repository root):
#   julia --project=benchmark benchmark/run.jl --label baseline [--workers 1,8] [--suite default]
#
# Writes benchmark/results/<label>.json. Compare two runs with
#   julia --project=benchmark benchmark/compare.jl baseline <other-label>

using Distributed
using GigaSOM
using DistributedData
using Dates
using JSON
using LinearAlgebra
using StableRNGs

# ---------------------------------------------------------------- arguments

function parseargs(args)
    opts = Dict{String,String}("label" => "unnamed", "workers" => "1,8", "suite" => "default")
    i = 1
    while i <= length(args)
        key = lstrip(args[i], '-')
        haskey(opts, key) || error("unknown option $(args[i])")
        opts[key] = args[i+1]
        i += 2
    end
    return opts
end

const OPTS = parseargs(ARGS)
const WORKER_COUNTS = parse.(Int, split(OPTS["workers"], ","))

# Each case: number of cells, markers, SOM side length, training epochs.
const SUITES = Dict(
    "quick" => [(cells = 100_000, dims = 30, som = 10, epochs = 3)],
    "default" => [
        (cells = 100_000, dims = 30, som = 10, epochs = 5),
        (cells = 1_000_000, dims = 40, som = 20, epochs = 5),
    ],
    "large" => [
        (cells = 1_000_000, dims = 40, som = 20, epochs = 5),
        (cells = 5_000_000, dims = 40, som = 32, epochs = 5),
    ],
)
const CASES = SUITES[OPTS["suite"]]

# ---------------------------------------------------------------- data

"""
Synthetic cytometry-like data: a mixture of `nclusters` Gaussian populations
with random centres and per-marker spreads. Deterministic for a given seed.
"""
function synthdata(cells, dims; nclusters = 25, seed = 1)
    rng = StableRNG(seed)
    centres = 3 .* randn(rng, nclusters, dims)
    spreads = 0.3 .+ 0.7 .* rand(rng, nclusters, dims)
    labels = rand(rng, 1:nclusters, cells)
    X = randn(rng, cells, dims)
    @inbounds for i = 1:cells, j = 1:dims
        X[i, j] = centres[labels[i], j] + spreads[labels[i], j] * X[i, j]
    end
    return X
end

"Mean Euclidean distance from each row of `X` to its nearest codebook vector."
function quantization_error(X, codes)
    cn = sum(abs2, codes; dims = 2)
    total = 0.0
    bs = 100_000
    for s = 1:bs:size(X, 1)
        B = X[s:min(s + bs - 1, end), :]
        D = sum(abs2, B; dims = 2) .- 2 .* (B * codes') .+ cn'
        total += sum(sqrt.(max.(minimum(D; dims = 2), 0.0)))
    end
    return total / size(X, 1)
end

# ---------------------------------------------------------------- environment

function gitinfo()
    root = dirname(@__DIR__)
    commit = try
        readchomp(`git -C $root rev-parse --short HEAD`)
    catch
        "unknown"
    end
    dirty = try
        !isempty(readchomp(`git -C $root status --porcelain -- src`))
    catch
        false
    end
    branch = try
        readchomp(`git -C $root rev-parse --abbrev-ref HEAD`)
    catch
        "unknown"
    end
    return (commit = commit, branch = branch, src_dirty = dirty)
end

function gpuinfo()
    try
        readchomp(`nvidia-smi --query-gpu=name,memory.total --format=csv,noheader`)
    catch
        "none"
    end
end

# ---------------------------------------------------------------- benchmark

function setworkers(n)
    nprocs() > 1 && rmprocs(workers())
    addprocs(n; exeflags = `--project=$(Base.active_project()) --threads=1`)
    @everywhere workers() @eval using GigaSOM, DistributedData
    return nothing
end

timeit(f) = (t = time_ns(); r = f(); ((time_ns() - t) / 1e9, r))

function runcase(case, nworkers)
    X = synthdata(case.cells, case.dims)
    di = scatter_array(:benchData, X, workers())

    som0 = initGigaSOM(di, case.som, case.som; seed = 42)

    t_train, som = timeit(() -> trainGigaSOM(som0, di; epochs = case.epochs))
    # mapping and embedding are cheap enough to repeat; report the fastest run
    t_map = minimum(1:3) do _
        t, mi = timeit(() -> mapToGigaSOM(som, di))
        unscatter(mi)
        t
    end
    t_embed = minimum(1:3) do _
        t, ei = timeit(() -> embedGigaSOM(som, di))
        unscatter(ei)
        t
    end

    qe = quantization_error(X, som.codes)

    unscatter(di)

    r = (
        cells = case.cells,
        dims = case.dims,
        som = "$(case.som)x$(case.som)",
        epochs = case.epochs,
        workers = nworkers,
        train_s = t_train,
        train_per_epoch_s = t_train / case.epochs,
        map_s = t_map,
        embed_s = t_embed,
        cells_per_s_train = case.cells * case.epochs / t_train,
        quantization_error = qe,
    )
    println(
        rpad("$(case.cells) x $(case.dims), som $(r.som), w=$nworkers", 40),
        "train/epoch ",
        lpad(round(r.train_per_epoch_s; digits = 3), 9),
        " s   map ",
        lpad(round(t_map; digits = 3), 8),
        " s   embed ",
        lpad(round(t_embed; digits = 3), 8),
        " s   QE ",
        round(qe; digits = 4),
    )
    return r
end

function main()
    results = []
    for nw in WORKER_COUNTS
        setworkers(nw)
        # warm-up: compile everything on a tiny problem so timings exclude JIT
        runcase((cells = 2_000, dims = 5, som = 4, epochs = 1), nw)
        println("-"^110)
        for case in CASES
            push!(results, runcase(case, nw))
        end
        println("="^110)
    end

    out = Dict(
        "label" => OPTS["label"],
        "suite" => OPTS["suite"],
        "timestamp" => string(now()),
        "julia" => string(VERSION),
        "cpu" => Sys.cpu_info()[1].model,
        "cpu_threads" => Sys.CPU_THREADS,
        "blas_threads" => BLAS.get_num_threads(),
        "gpu" => gpuinfo(),
        "git" => gitinfo(),
        "results" => results,
    )
    path = joinpath(@__DIR__, "results", "$(OPTS["label"]).json")
    open(io -> JSON.print(io, out, 2), path, "w")
    println("wrote $path")
end

main()
