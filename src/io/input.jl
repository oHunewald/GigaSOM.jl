"""
    readFlowset(filenames)

Create a dictionary with filenames as keys and daFrame as values

# Arguments:
- `filenames`: Array of type string
"""
function readFlowset(filenames)

    flowFrame = Dict()

    # read all FCS files into flowFrame
    for name in filenames # file list
        flowrun = FileIO.load(name) # FCS file

        # get metadata
        # FCSFiles returns a dict with coumn names as key
        # As the dict is not in order, use the name column form meta
        # to sort the Dataframe after cast.
        meta = getMetaData(flowrun)
        markers = meta[!, Symbol("\$PnS")]
        markersIsotope = meta[!, Symbol("\$PnN")]
        # if marker labels are empty use Isotope marker as column names
        if markers[1] == " "
            markers = markersIsotope
        end
        flowDF = DataFrame(flowrun.data)
        # sort the DF according to the marker list
        flowDF = flowDF[:, Symbol.(markersIsotope)]
        cleanNames!(markers)

        names!(flowDF, Symbol.(markers), makeunique=true)
        flowFrame[name] = flowDF
    end

    return flowFrame
end


"""
    readFlowFrame(filename)

Create a dictionary with a single flowframe

# Arguments:
- `filename`: string
"""
function readFlowFrame(filename)

    flowFrame = Dict()

    # read single FCS file into flowFrame
    flowrun = FileIO.load(filename) # FCS file

    # get metadata
    # FCSFiles returns a dict with coumn names as key
    # As the dict is not in order, use the name column form meta
    # to sort the Dataframe after cast.
    meta = getMetaData(flowrun)
    markers = meta[!, Symbol("\$PnS")]
    markersIsotope = meta[!, Symbol("\$PnN")]
    # if marker labels are empty use Isotope marker as column names
    if markers[1] == " "
        markers = markersIsotope
    end
    flowDF = DataFrame(flowrun.data)
    # sort the DF according to the marker list
    flowDF = flowDF[:, Symbol.(markersIsotope)]
    cleanNames!(markers)

    names!(flowDF, Symbol.(markers), makeunique=true)
    flowFrame[filename] = flowDF

    return flowFrame
end
