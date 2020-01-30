# Test the GigaSOM package first:
import Pkg
Pkg.activate("GigaSOM")
Pkg.update()

#Pkg.test("GigaSOM")
using Distributed
using GigaSOM

checkDir()
cwd = pwd()

dataPath = "/home/users/ohunewald/data"
cd(dataPath)
md = GigaSOM.DataFrame(GigaSOM.XLSX.readtable("metadata_8.xlsx", "Sheet1", infer_eltypes=true)...)
panel = GigaSOM.DataFrame(GigaSOM.XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)

lineageMarkers, functionalMarkers = getMarkers(panel)

nWorkers = 4
using ClusterManagers
addprocs(SlurmManager(nWorkers), topology=:master_worker)
@everywhere using GigaSOM

# R: Array of reference to each data files per worker
# use '_' or just "R, " to ignore the second return value
# second return value is used later for indexing the data files
R, _ = loadData(dataPath, md, nWorkers, panel=panel, reduce=true, transform=true)

som = initGigaSOM(R, 10, 10)

cc = map(Symbol, vcat(lineageMarkers, functionalMarkers))

@time som = trainGigaSOM(som, R)

winners = mapToGigaSOM(som, R)

embed = embedGigaSOM(som, R, k=10, smooth=0.0, adjust=0.5)

rmprocs(workers())
cd(cwd)