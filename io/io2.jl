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
# using ParallelDataTransfer

@everywhere using GigaSOM, ParallelDataTransfer, DataFrames

@everywhere function initDAF()
    daf = DataFrame()
end

# @everywhere function getRandomSamples(daf, n)

#     nSamples = size(daf.fcstable, 1)
#     return daf.fcstable[rand(1:nSamples, n), :]
# end

# @everywhere function getRandomSamples(n)

#     nSamples = size(daf.fcstable, 1)
#     daf.fcstable[rand(1:nSamples, n), :]
#     return daf
# end



# load files in parallel
N = convert(Int64, length(md.file_name)/nWorkers)
R = Vector{Any}(undef,nworkers())
@sync begin
    for (idx, pid) in enumerate(workers())
        R[idx] =  fetch(@spawnat pid initDAF())
    end
end

@show @time begin
    for (idx, pid) in enumerate(workers())
        datalist = md[(idx-1)*N+1:idx*N, :]
        println(datalist)

        # load FCS file
        fcsRaw = readFlowset(md.file_name)

        # clean names
        cleanNames!(fcsRaw)

        # create daFrame
        daf = createDaFrame(fcsRaw, md, panel)

        # remotecall_fetch(()->daf, pid)
        # fetch(@spawnat pid sendSamples(daf))
        ParallelDataTransfer.sendto(pid, daf=daf)
    end
end

# rc = RemoteChannel(()->Channel(3));

# v = [0]

# for i in 1:3
#     v[1] = i                          # Reusing `v`
#     put!(rc, v)
# end

# result = [take!(rc) for _ in 1:3]
# println(result[1])


cd(baseDir)
rmprocs(workers())
