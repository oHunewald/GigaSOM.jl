"""
        initGigaSOM(train, xdim, ydim = xdim;  norm = :none, toroidal = false)

Initialises a SOM.

# Arguments:
- `train`: training data
- `xdim, ydim`: geometry of the SOM
           If DataFrame, the column names will be used as attribute names.
           Codebook vectors will be sampled from the training data.
- `norm`: optional normalisation; one of :`minmax, :zscore or :none`
- `toroidal`: optional flag; if true, the SOM is toroidal.
"""
function initGigaSOM( train, xdim, ydim = xdim;
             norm::Symbol = :none, toroidal = false)

    if typeof(train) == DataFrame
        colNames = [String(x) for x in names(train)]
    else
        colNames = ["x$i" for i in 1:size(train,2)]
    end

    train = convertTrainingData(train)

    numCodes = xdim * ydim

    # normalise training data:
    train, normParams = normTrainData(train, norm)

    # initialise the codes with random samples
    codes = train[rand(1:size(train,1), numCodes),:]
    grid = gridRectangular(xdim, ydim)

    normParams = convert(DataFrame, normParams)
    names!(normParams, Symbol.(colNames))

    # create X,y-indices for neurons:
    #
     x = y = collect(1:numCodes)
    indices = DataFrame(X = x, Y = y)

    # make SOM object:
    som = Som(codes = codes, colNames = colNames,
           normParams = normParams, norm = norm,
           xdim = xdim, ydim = ydim,
           numCodes = numCodes,
           grid = grid, indices = indices,
           toroidal = toroidal,
           population = zeros(Int, numCodes))
    return som
end


"""
    trainGigaSOM(som::Som, train::DataFrame, kernelFun = gaussianKernel,
                        r = 0.0, epochs = 10)

# Arguments:
- `som`: object of type Som with an initialised som
- `train`: training data
- `kernel::function`: optional distance kernel; one of (`bubbleKernel, gaussianKernel`)
            default is `gaussianKernel`
- `r`: optional training radius.
       If r is not specified, it defaults to √(xdim^2 + ydim^2) / 2
Training data must be convertable to Array{Float34,2} with `convert()`.
Training samples are row-wise; one sample per row. An alternative kernel function
can be provided to modify the distance-dependent training. The function must fit
to the signature fun(x, r) where x is an arbitrary distance and r is a parameter
controlling the function and the return value is between 0.0 and 1.0.
"""
function trainGigaSOM(som::Som, train::DataFrame; kernelFun::Function = gaussianKernel,
						rStart = 0.0, rFinal=0.1, decay="linear", epochs=10)

    train = convertTrainingData(train)

    # set default radius:
    if rStart == 0.0
        rStart = √(som.xdim^2 + som.ydim^2) / 2
        @info "The radius has been determined automatically."
    end

	r = rStart

    dm = distMatrix(som.grid, som.toroidal)

    codes = som.codes

    nWorkers = nprocs()
    dTrain = distribute(train)

    for j in 1:epochs

		globalSumNumerator = zeros(Float64, size(codes))
		globalSumDenominator = zeros(Float64, size(codes)[1])

		println("Epoch: $j")

		nnTree = BruteTree(Array{Float64,2}(codes'))

		if nWorkers > 1
			# distribution across workers
			R = Array{Future}(undef,nWorkers, 1)
			@sync for (p, pid) in enumerate(workers())
			  @async R[p] = @spawnat pid begin
			     doEpoch(localpart(dTrain), codes, nnTree)
			  end
			end

			@sync for (p, pid) in enumerate(workers())
			  tmp = fetch(R[p])
			  globalSumNumerator += tmp[1]
			  globalSumDenominator += tmp[2]
			end
		else
			# only batch mode
			sumNumerator, sumDenominator = doEpoch(localpart(dTrain), codes, nnTree)

			globalSumNumerator += sumNumerator
			globalSumDenominator += sumDenominator
		end

		rEpoch = getRadius(rStart, rFinal, j-1, decay, epochs)
		println("Epoch: $j (radius: $rEpoch)")

		wEpoch = kernelFun(dm, rEpoch)
		codes = (wEpoch*globalSumNumerator) ./ (wEpoch*globalSumDenominator)
    end

    som.codes[:,:] = codes[:,:]

    return som
end


"""
    doEpoch(x::Array{Float64}, codes::Array{Float64}, dm::Array{Float64},
            kernelFun::Function, r::Number, toroidal::Bool)

vectors and the adjustment in radius after each epoch.

# Arguments:
- `x`: training Data
- `codes`: Codebook
- `dm`: distance matrix of all neurons of the SOM
- `kernelFun`: distance kernel function of type fun(x, r)
- `r`: training radius
- `toroidal`: if true, the SOM is toroidal.
"""
function doEpoch(x::Array{Float64, 2}, codes::Array{Float64, 2}, nnTree)

     sumNumerator = zeros(Float64, size(codes))
     sumDenominator = zeros(Float64, size(codes)[1])

     # for each sample in dataset / trainingsset
     for s in 1:size(x, 1)

		 (bmuIdx, bmuDist) = knn(nnTree, x[s, :], 1)

		 target = bmuIdx[1]

		 @inbounds @views begin
		 	sumNumerator[target, :] .+= x[s, :]
	 	 end
		 sumDenominator[target] += 1

     end

     return sumNumerator, sumDenominator
end


"""
    mapToGigaSOM(som::Som, data)

Return a DataFrame with X-, Y-indices and index of winner neuron for
every row in data.

# Arguments
- `som`: a trained SOM
- `data`: Array or DataFrame with training data.

Data must have the same number of dimensions as the training dataset
and will be normalised with the same parameters.
"""
function mapToGigaSOM(som::Som, data::DataFrame)

    data::Array{Float64,2} = convertTrainingData(data)
    if size(data,2) != size(som.codes,2)
        println("    data: $(size(data,2)), codes: $(size(som.codes,2))")
        error(SOM_ERRORS[:ERR_COL_NUM])
    end

    nWorkers = nprocs()
    dData = distribute(data)
    vis = Int64[]

    if nWorkers > 1
        # distribution across workers
        R = Array{Future}(undef,nWorkers, 1)
	@sync for (p, pid) in enumerate(workers())
             @async R[p] = @spawnat pid begin
                visual(som.codes, localpart(dData))
             end
         end

         @sync begin
	     for (p, pid) in enumerate(sort!(workers()))
                 append!(vis, fetch(R[p]))
             end
         end
    else
        vis = visual(som.codes, data)
    end

    return DataFrame(index = vis)
end


"""
    getRadius(initRadius::Float64, iteration::Int64, decay::String, epochs::Int64)
Return a new neighbourhood radius
# Arguments
- `initRadius`: Initial Radius
- `iteration`: Training iteration
- `decay`: Linear of Exponential decay
- `epochs`: Total number of epochs
Data must have the same number of dimensions as the training dataset
and will be normalised with the same parameters.
"""
function getRadius(initRadius::Float64, finalRadius::Float64, iteration::Int64,
				decay::String, epochs::Int64)

	if decay == "linear"
		# timeConstant is delta R in previous code
		timeConstant = (initRadius - finalRadius) / (epochs-1)
		return initRadius - (iteration * timeConstant)
	elseif decay == "exp"
		timeConstant = epochs / log(initRadius)
		return initRadius * exp(-iteration / timeConstant)
	end

end
