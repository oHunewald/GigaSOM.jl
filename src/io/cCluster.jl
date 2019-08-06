using RCall
@rlibrary consens2

function cc_plus(codes::Array{Float64, 2})
    plot_outdir = "consensus_plots"
    nmc = 50
    codesT = Matrix(codes')
    mc = ConsensusClusterPlus_2(codesT, maxK = nmc, reps = 100,
                               pItem = 0.9, pFeature = 1, title = plot_outdir, plot = "png",
                               clusterAlg = "hc", innerLinkage = "average", finalLinkage = "average",
                               distance = "euclidean", seed = 1234)

    return convert(Vector, mc)
end
