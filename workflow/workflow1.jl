using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed, SHA, JSON

checkDir()
#create genData and data folder and change dir to dataPath
cwd = pwd()

datapath = "/Users/ohunewald/work/SysTact/pre_data/SYSTACT_555_CD3neg"
# datapath = "/Users/ohunewald/work/data_felD1"
cd(datapath)
md = DataFrame(XLSX.readtable("metadata_small.xlsx", "Sheet1", infer_eltypes=true)...)
# md = DataFrame(XLSX.readtable("metadata.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)

lineageMarkers, functionalMarkers = getMarkers(panel)

fcsRaw = readFlowset(md.file_name)
cleanNames!(fcsRaw)

# create daFrame file
daf = createDaFrame(fcsRaw, md, panel)

cd(cwd)
using StatsPlots
using Statistics
using StatsBase
using MultivariateStats
include("../src/visualization/Plotting.jl")

# some plotting
plotPCA(daf,md)
#fix the seed
Random.seed!(1)

p = addprocs(2)

@everywhere using DistributedArrays
@everywhere using GigaSOM
@everywhere using Distances

# only use lineageMarkers for clustering
(lineageMarkers,)= getMarkers(panel)
cc = map(Symbol, lineageMarkers)
dfSom = daf.fcstable[:,cc]

som2 = initGigaSOM(dfSom, 10, 10)
som2 = trainGigaSOM(som2, dfSom, epochs = 2, rStart = 6.0)

winners = mapToGigaSOM(som2, dfSom)

embed = embedGigaSOM(som2, dfSom, k=10, smooth=0.0, adjust=0.5)
