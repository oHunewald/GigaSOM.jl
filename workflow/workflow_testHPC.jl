using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed, SHA, JSON

checkDir()
#create genData and data folder and change dir to dataPath
cwd = pwd()

datapath = "/home/users/ohunewald/data"
cd(datapath)
md = DataFrame(XLSX.readtable("metadata_100.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)

lineageMarkers, functionalMarkers = getMarkers(panel)

fcsRaw = readFlowset(md.file_name)
cleanNames!(fcsRaw)

# create daFrame file
daf = createDaFrame(fcsRaw, md, panel)

cd(cwd)

#fix the seed
Random.seed!(1)

p = addprocs(10, topology=:master_worker)
@everywhere using GigaSOM

# only use lineageMarkers for clustering
(lineageMarkers,)= getMarkers(panel)
cc = map(Symbol, lineageMarkers)
dfSom = daf.fcstable[:,cc]

som2 = initGigaSOM(dfSom, 10, 10)


som2 = trainGigaSOM(som2, dfSom, epochs = 1)
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
rmprocs(workers())

p = addprocs(20, topology=:master_worker)
@everywhere using GigaSOM
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
rmprocs(workers())

p = addprocs(40, topology=:master_worker)
@everywhere using GigaSOM
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
rmprocs(workers())

p = addprocs(80, topology=:master_worker)
@everywhere using GigaSOM
@time som2 = trainGigaSOM(som2, dfSom, epochs = 10)
rmprocs(workers())
