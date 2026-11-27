# Compare two benchmark result files.
#
# Usage: julia --project=benchmark benchmark/compare.jl <base-label> <new-label>
#
# Prints per-case timings and speedups (base / new). Quantization error (QE)
# is shown for both runs so result-quality regressions are visible.

using JSON
using Printf

load(label) = JSON.parsefile(joinpath(@__DIR__, "results", "$label.json"))

function main(baselabel, newlabel)
    base, new = load(baselabel), load(newlabel)
    key(r) = (r["cells"], r["dims"], r["som"], r["workers"])
    bidx = Dict(key(r) => r for r in base["results"])

    println("base: $baselabel ($(base["git"]["commit"]))   new: $newlabel ($(new["git"]["commit"]))\n")
    @printf(
        "%-34s %21s %21s %21s %17s\n",
        "case",
        "train/epoch s (x)",
        "map s (x)",
        "embed s (x)",
        "QE base→new"
    )
    for r in new["results"]
        k = key(r)
        haskey(bidx, k) || continue
        b = bidx[k]
        cell(f) = @sprintf("%7.3f→%7.3f %4.1fx", b[f], r[f], b[f] / r[f])
        @printf(
            "%-34s %21s %21s %21s %8.4f→%7.4f\n",
            "$(k[1])x$(k[2]) som $(k[3]) w=$(k[4])",
            cell("train_per_epoch_s"),
            cell("map_s"),
            cell("embed_s"),
            b["quantization_error"],
            r["quantization_error"]
        )
    end
end

length(ARGS) == 2 || error("usage: compare.jl <base-label> <new-label>")
main(ARGS...)
