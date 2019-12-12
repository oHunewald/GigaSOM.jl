using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed, SHA, JSON

try
	using UMAP
catch
	Pkg.add("UMAP")
end

using UMAP

#create genData and data folder and change dir to dataPath
cwd = pwd()

# datapath = "/home/users/ohunewald/systact/test_metadata"
# datapath = "/home/users/ohunewald/systact/data"
datapath = "/Users/ohunewald/work/SysTact/test_metadata"

cd(datapath)

all_fcs = CSV.read("all_fcs.csv")
md = DataFrame(XLSX.readtable("metadata_test.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)
lineageMarkers, functionalMarkers = getMarkers(panel)
cc = map(Symbol, lineageMarkers)

fcs_lineage = all_fcs[:, cc]
fcs_matrix = Matrix(fcs_lineage)

# naive random sampling
using StatsBase
idx = sample(1:size(fcs_matrix,1), 4000)
fcs_short = fcs_matrix[idx, :]
embedding = umap(fcs_short')

using Plots
embedding = Matrix(embedding')
gr()

plot(embedding[:,1], embedding[:,2], alpha=0.2,markersize=1.0, 
    seriestype=:scatter, title="My Scatter Plot")