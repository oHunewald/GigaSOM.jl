# Load and transform
# build the general workflow to have the data ready

#=
using FCSFiles for loading
as this function is only the basic parsing of the binary
FCS, we need to see what functionality is missing and
extend this in the original package
=#
# ENV["PYTHON"] = Sys.which("PYTHON")
ENV["PYTHON"] = "/usr/local/bin/python3.6"

using GigaSOM, DataFrames, XLSX, CSV, Test, Random, Distributed, SHA, JSON, PyCall

fcsparser = pyimport("fcsparser")

dataPath = ("../data_felD1")
cd(dataPath)
md = DataFrame(XLSX.readtable("metadata.xlsx", "Sheet1", infer_eltypes=true)...)
panel = DataFrame(XLSX.readtable("panel.xlsx", "Sheet1", infer_eltypes=true)...)

# two values are empty, do not try to parse them
# markers = [convert(String, i) for i in df.values if i != nothing]

lineageMarkers = vec(panel.Antigen[panel.Lineage .== 1, : ])
cleanNames!(lineageMarkers)
functionalMarkers = vec(panel.Antigen[panel.Functional .== 1, : ])
cleanNames!(functionalMarkers)

# check if all lineageMarkers are in markers
# issubset(lineageMarkers, markers)
# issubset(functionalMarkers, markers)

fcsRaw = readFlowset(md, fcsparser)

# create daFrame file
daf = createDaFrame(fcsRaw, md, panel, lineageMarkers, functionalMarkers)

# change the directory back to the current directory
# cd(cwd)

# CSV.write(dataPath*"/daf.csv", daf.fcstable)

# @testset "Cleaning names" begin
#     for i in eachindex(lineageMarkers)
#         @test !in("-",i)
#     end
#     for i in eachindex(functionalMarkers)
#         @test !in("-",i)
#     end
#     for (k,v) in fcsRaw
#         colnames = names(v)
#         for i in eachindex(colnames)
#             @test !in("-",i)
#         end
#     end
# end
#
# @testset "Checksums" begin
#     cd(dataPath)
#     filesNames = readdir()
#     csDict = Dict()
#     for f in filesNames
#         cs = bytes2hex(sha256(f))
#         csDict[f] = cs
#     end
#     cd(cwd*"/checkSums")
#     csTest = JSON.parsefile("csTest.json")
#     @test csDict == csTest
#     cd(cwd)
# end

# cd(cwd)
