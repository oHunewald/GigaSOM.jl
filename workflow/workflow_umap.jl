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
datapath = "/home/users/ohunewald/systact/data"
# datapath = "/Users/ohunewald/work/SysTact/test_metadata"

cd(datapath)

all_fcs = CSV.read("all_fcs.csv")
cell_clustering = CSV.read("cell_clustering_grid_20_no_tcr.csv")
# eSOM = CSV.read("embed.csv")
md = DataFrame(XLSX.readtable("metadata_no_tcr.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel_no_tcr.xlsx", "Sheet1", infer_eltypes=true)...)
lineageMarkers, functionalMarkers = getMarkers(panel)
cc = map(Symbol, lineageMarkers)

fcs_lineage = all_fcs[:, cc]
fcs_matrix = Matrix(fcs_lineage)

# naive random sampling
using StatsBase
idx = sample(1:size(fcs_matrix,1), 5000000)
fcs_short = fcs_matrix[idx, :]
embedding = umap(fcs_short')

gdf = DataFrame(fcs_short,cc)
gdf[!, :sample_id] = all_fcs.sample_id[idx]
gdf[!, :embedding1] = embedding'[:,1]
gdf[!, :embedding2] = embedding'[:,2]
gdf[!, :cClustering] = cell_clustering.id[idx]
# adding the condition
idx = indexin(gdf.sample_id, md.sample_id)
gdf[!, :condition] = md.condition[idx]

# adding the timepoint
idx = indexin(gdf.sample_id, md.sample_id)
gdf[!, :timepoint] = md.timepoint[idx]

Color = color_clusters[gdf.cClustering]

CSV.write("gdf_no_tcr.csv", gdf)

#=
using PyPlot

fig = figure(figsize=(10,10))

title("EmbedSOM")
R = PyPlot.scatter(gdf.embedding1,gdf.embedding2, color = Color)

legend(loc="right")
PyPlot.savefig("pca1_2_fam.pdf") 




using RCall
@rlibrary ggplot2
@rlibrary scattermore

p = ggplot(gdf, aes(x = :embedding1, y = :embedding2)) +
  geom_point(size = 0, color = Color) +
  theme_bw() +
  coord_fixed() 
p

p + facet_wrap(gdf.timepoint)
=#
# using EmbedSOM
# gdf = all_fcs
# gdf[!, :embedding1] = eSOM[:,2]
# gdf[!, :embedding2] = eSOM[:,3]
# gdf[!, :cClustering] = cell_clustering[:,1]

# v1= df_pca.sample_id; v2=md.sample_id
# idxs = indexin(v1, v2)
# df_pca[:condition] = md.condition[idxs]



# using UMAP
# gdf[!, :embedding1] = embedding'[:,1]
# gdf[!, :embedding2] = embedding'[:,2]

# gdf[!, :cClustering] = cell_clustering_downsample[:,1]




#=

color_clusters = ["#DC050C", "#FB8072", "#1965B0", "#7BAFDE", "#882E72",
				"#B17BA6", "#FF7F00", "#FDB462", "#E7298A", "#E78AC3",
				"#33A02C", "#B2DF8A", "#55A1B1", "#8DD3C7", "#A6761D",
				"#E6AB02", "#7570B3", "#BEAED4", "#666666", "#999999",
				"#aa8282", "#d4b7b7", "#8600bf", "#ba5ce3", "#808000",
				"#aeae5c", "#1e90ff", "#00bfff", "#56ff0d", "#ffff00",
				"#000000", "#0000ff", "#800080", "#ffb6c1", "#003366",
				"#00ff00", "#666666", "#b0e0e6", "#c39797", "#66cdaa",
				"#ff6666", "#ffc3a0", "#ff00ff", "#333333", "#cccccc",
				"#088da5", "#c0d6e4", "#8b0000", "#660066", "#ff7f50",
				"#DC050C", "#FB8072", "#1965B0", "#7BAFDE", "#882E72",
				"#B17BA6", "#FF7F00", "#FDB462", "#E7298A", "#E78AC3",
				"#33A02C", "#B2DF8A", "#55A1B1", "#8DD3C7", "#A6761D",
				"#E6AB02", "#7570B3", "#BEAED4", "#666666", "#999999",
				"#aa8282", "#d4b7b7", "#8600bf", "#ba5ce3", "#808000",
				"#aeae5c", "#1e90ff", "#00bfff", "#56ff0d", "#ffff00",
				"#000000", "#0000ff", "#800080", "#ffb6c1", "#003366",
				"#00ff00", "#666666", "#b0e0e6", "#c39797", "#66cdaa",
				"#ff6666", "#ffc3a0", "#ff00ff", "#333333", "#cccccc",
				"#088da5", "#c0d6e4", "#8b0000", "#660066", "#ff7f50"]

=#
