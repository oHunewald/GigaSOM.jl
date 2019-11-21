__precompile__()
using Distributed, XLSX, DataFrames, FileIO

baseDir = pwd()

# dataPath = "/Users/ohunewald/work/PBMC8_fcs_files"
dataPath = "/Users/ohunewald/work/GigaSOM.jl/test/data"
cd(dataPath)

md = DataFrame(XLSX.readtable("PBMC8_metadata.xlsx", "Sheet1", infer_eltypes=true)...)
md_small = DataFrame(XLSX.readtable("PBMC8_metadata_small.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("PBMC8_panel.xlsx", "Sheet1", infer_eltypes=true)...)



# local read data function
nWorkers = 2

addprocs(nWorkers)
@everywhere using GigaSOM

@everywhere function loadData(md, panel)

    # load FCS file
    fcsRaw = readFlowset(md.file_name)

    # clean names
    cleanNames!(fcsRaw)

    # create daFrame
    daf = createDaFrame(fcsRaw, md, panel)

    # return a random sample
    gridSize = 100
    nSamples = convert(Int64, floor(gridSize/nworkers()))
    return daf.fcstable[rand(1:nSamples, nSamples), :]
end

#lineageMarkers, functionalMarkers = getMarkers(panel)
R = Vector{Any}(undef,nworkers())

# load files in parallel
N = convert(Int64, length(md_small.file_name)/nWorkers)

@show @time @sync begin
    for (idx, pid) in enumerate(workers())
        R[idx] =  fetch(@spawnat pid loadData(md_small[(idx-1)*N+1:idx*N, :], panel))
    end
end

cd(baseDir)
rmprocs(workers())
