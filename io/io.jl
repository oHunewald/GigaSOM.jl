
using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed, SHA, JSON

checkDir()
#create genData and data folder and change dir to dataPath
cwd = pwd()
#
dataPath = "/Users/ohunewald/work/data_felD1/"
cd(dataPath)
md = DataFrame(XLSX.readtable("metadata.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)
#
lineageMarkers, functionalMarkers = getMarkers(panel)

nWorkers = 2
addprocs(nWorkers)
@everywhere using GigaSOM

@info "processes added"



@info "loadData function defined"

R = Vector{Any}(undef,nworkers())

@info "loop started"
# load files in parallel
N = convert(Int64, length(md.file_name)/nWorkers)

@time @sync for (idx, pid) in enumerate(workers())
            #@show idx
            #@show pid
            @async R[idx] = @spawnat pid begin
                loadData(md.file_name[(idx-1)*N+1:idx*N],md, panel)
            end
    end


rmprocs(workers())





