using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed
cwd = pwd()
dataPath = homedir()*"/data"
#dataPath = homedir()*"/gigaTest2/data"
println(dataPath)
cd(dataPath)


const md = DataFrame(XLSX.readtable("metadata_100.xlsx", "Sheet1")...)
const panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1")...)
println(md)
const lineageMarkers = vec(panel.Antigen[panel.Lineage .== 1, : ])
cleanNames!(lineageMarkers)
const functionalMarkers = vec(panel.Antigen[panel.Functional .== 1, : ])
cleanNames!(functionalMarkers)
println("try to load the data")
const fcsRaw = readFlowset(md.file_name)
println("back with fcsRaw")
cleanNames!(fcsRaw)
println("back from cleannames")

# create daFrame file
daf = createDaFrame(fcsRaw, md, panel)
