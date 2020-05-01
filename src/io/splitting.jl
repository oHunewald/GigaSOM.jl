"""
    slicesof(lengths::Vector{Int}, slices::Int)::Vector{Tuple{Int,Int,Int,Int}}

Given a list of `lengths` of input arrays, compute a slicing into a specified
amount of equally-sized `slices`.

The output is a vector of 4-tuples where each specifies how to create one
slice. The i-th tuple field contains, in order:

- the index of input array at which the i-th slice begins
- first element of the i-th slice in that input array
- the index of input array with the last element of the i-th slice
- the index of the last element of the i-th slice in that array
"""
function slicesof(lengths::Vector{Int}, slices::Int)::Vector{Tuple{Int,Int,Int,Int}}
    nfiles = length(lengths)
    total = sum(lengths)
    sliceLen = repeat([div(total, slices)], slices)

    for i = 1:mod(total, slices)
        sliceLen[i] += 1
    end

    result = repeat([(0, 0, 0, 0)], slices)

    ifile = 1 # file in the window
    off = 0 # cells already taken from that window
    for i = 1:slices
        startFile = ifile
        startOff = off + 1
        avail = lengths[ifile] - off
        while avail < sliceLen[i]
            ifile += 1
            off = 0
            avail += lengths[ifile]
        end
        rest = avail - sliceLen[i]
        off = lengths[ifile] - rest
        if startOff > lengths[startFile] && startFile < ifile
            startOff = 1
            startFile += 1
        end
        result[i] = (startFile, startOff, ifile, off)
    end
    result
end

"""
    vcollectSlice(loadMtx, (startFile, startOff, finalFile, finalOff)::Tuple{Int,Int,Int,Int})::Matrix

Given a method to obtain matrix content (`loadMtx`), reconstruct a slice from
the information generated by `slicesof`.

This function is specialized for reconstructing matrices and arrays, where the
"element counts" split by `slicesof` are in fact matrix rows. The function is
therefore named _v_collect (the slicing and concatenation is _v_ertical).

The actual data content and loading method is abstracted out -- function
`loadMtx` gets the index of the input part that it is required to fetch (e.g.
index of one FCS file), and is expected to return that input part as a whole
matrix. `vcollectSlice` correctly calls this function as required and extracts
relevant portions of the matrices, so that at the end the whole slice can be
pasted together.

Example:

    # get a list of files
    filenames=["a.fcs", "b.fcs"]
    # get descriptions of 5 equally sized parts of the data
    slices = slicesof(loadFCSSizes(filenames), 5)

    # reconstruct first 3 columns of the first slice
    mySlice = vcollectSlice(
        i -> last(loadFCS(slices[i]))[:,1:3],
        slices[1])
    # (note: function loadFCS returns 4 items, the matrix is the last one)
"""
function vcollectSlice(
    loadMtx,
    (startFile, startOff, finalFile, finalOff)::Tuple{Int,Int,Int,Int},
)::Matrix
    vcat([
        begin
            m = loadMtx(i)
            beginIdx = i == startFile ? startOff : 1
            endIdx = i == finalFile ? finalOff : size(m, 1)
            m[beginIdx:endIdx, :]
        end for i = startFile:finalFile
    ]...)
end

"""
    collectSlice(loadVec, (startFile, startOff, finalFile, finalOff)::Tuple{Int,Int,Int,Int})::Vector

Alternative of `vcollectSlice` for 1D vectors.
"""
function collectSlice(
    loadVec,
    (startFile, startOff, finalFile, finalOff)::Tuple{Int,Int,Int,Int},
)::Vector
    vcat([
        begin
            v = loadVec(i)
            beginIdx = i == startFile ? startOff : 1
            endIdx = i == finalFile ? finalOff : length(v)
            v[beginIdx:endIdx]
        end for i = startFile:finalFile
    ]...)
end
