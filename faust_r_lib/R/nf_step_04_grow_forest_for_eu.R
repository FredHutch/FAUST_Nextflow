nf_step_04_grow_forest_for_eu <- function(
                                          activeChannelsPath,
                                          experimentalUnit,
                                          startingCellPop,
                                          threadNumber
                                          )
{
    #function to 
    activeChannels <- readRDS(activeChannelsPath)
    levelExprs <- readRDS(paste0(experimentalUnit,"_levelExprs.rds"))
    levelRes <- readRDS(paste0(experimentalUnit,"_levelRes.rds"))
    levelExprs <- levelExprs[,activeChannels,drop=FALSE]
    levelRes <- levelRes[,activeChannels,drop=FALSE]
    resFlag <- FALSE
    for (colNum in seq(ncol(levelRes))) {
        if (length(which(levelRes[,colNum] > 0))) {
            resFlag <- TRUE
            break
        }
    }
    annF <- .nfGrowAnnotationForest(
        dataSet=levelExprs,
        numberIterations=1,
        pValueThreshold=0.25,
        minimumClusterSize=25,
        randomCandidateSearch=FALSE,
        maximumSearchDepth=2,
        numberOfThreads=threadNumber,
        maximumGatingNum=1e10,
        anyValueRestricted=resFlag,
        resValMatrix=levelRes,
        cutPointUpperBound=2,
        getDebugInfo=FALSE,
        randomSeed=123,
        subSamplingThreshold=500001,
        subSampleSize=500000,
        subSampleIter=1,
        recordCounts=FALSE,
        recordIndices=FALSE
    )
    saveRDS(annF,paste0(experimentalUnit,"_",startingCellPop,"_annF.rds"))
    ePop <- apply(levelRes,2,function(x){length(which(x==0))})
    names(ePop) <- colnames(levelExprs)
    af <- annF[["gateData"]]
    pAnnF <- .nfParseAnnotationForest(af,ePop)
    saveRDS(pAnnF,paste0(experimentalUnit,"_",startingCellPop,"_pAnnF.rds"))
    return()
}

.nfGrowAnnotationForest <- function(
                                    dataSet,
                                    numberIterations = 1,
                                    pValueThreshold = 0.35,
                                    minimumClusterSize = 25,
                                    maximumSearchDepth = ncol(dataSet),
                                    maximumGatingNum = 1000,
                                    maximumAntimodeNumber = 100,
                                    maximumSearchTime=1e6,
                                    maximumRunTime = 1e6,
                                    annotationVec = colnames(dataSet),
                                    numberOfThreads=1,
                                    randomCandidateSearch=FALSE,
                                    anyValueRestricted=FALSE,
                                    resValMatrix=matrix(0,nrow=2,ncol=2),
                                    getDebugInfo=FALSE,
                                    cutPointUpperBound=2,
                                    gaussianScaleParameter=4,
                                    randomSeed=0,
                                    allowRepeatedSplitting=FALSE,
                                    subSamplingThreshold=1e5,
                                    subSampleSize=1e4,
                                    subSampleIter=100,
                                    recordCounts=FALSE,
                                    recordIndices=FALSE
                                    )
{
    if (!is.matrix(dataSet))
        stop("Must provide a numeric R matrix")
    if (!is.double(pValueThreshold))
        stop("The p-value threshold must be a double precison number.")
    if ((pValueThreshold < 0.01) || (pValueThreshold > 0.99))
        stop("The p-value threshold for the dip test must be between  0.01 and 0.99")
    if ((!is.numeric(minimumClusterSize)) || (minimumClusterSize < 10))
        stop("A cluster cannot be smaller than 10 observations")
    if ((!is.numeric(maximumSearchDepth)) || (maximumSearchDepth < 1))
        stop("Search depth must be a natural number > 1")
    if ((!is.numeric(maximumGatingNum)) || (maximumGatingNum < 2))
        stop("Must search for more than 1 gating example")
    if (nrow(dataSet) < minimumClusterSize)
        stop("Too few observations for data")
    if (max(is.na(annotationVec)))
        stop('User must assign column names to input data set. colnames(dataSet) <- c("user", "entry",...)')
    if (maximumRunTime <= 0)
        stop("User must assign positive value for maximumRunTime (in seconds)")
    if (gaussianScaleParameter < 0.1)
        stop("Gaussian scale parameter smaller than 0. Not possible.")
    if (!(identical(randomCandidateSearch,TRUE) || identical(randomCandidateSearch,FALSE))) 
        stop("User must set randomCandidateSearch either to TRUE or FALSE.")
    if (!(identical(anyValueRestricted,TRUE) || identical(anyValueRestricted,FALSE))) 
        stop("User must set anyValueRestricted either to TRUE or FALSE.")
    if (!(identical(allowRepeatedSplitting,TRUE) || identical(allowRepeatedSplitting,FALSE))) 
        stop("User must set allowRepeatedSplitting either to TRUE or FALSE.")


    aCols <- apply(dataSet,2,length)
    uCols <- apply(dataSet,2,function(x){length(unique(x))})
    rCols <- uCols/aCols
    mCol <- min(rCols)

    firstIteration <- TRUE
    remainingIterations <- numberIterations
    startTime <- proc.time()
    timeDiff <- proc.time()-startTime
    elapsedTime <- as.numeric(timeDiff[3])
    if (randomSeed > 0) {
        set.seed(randomSeed)
    }
    while ((remainingIterations > 0) && (elapsedTime <= maximumRunTime)) {
        if (((remainingIterations %% 100) == 0) || (getDebugInfo)) {
            print(paste("remaining iterations: ", remainingIterations, sep=""))
        }
        if (randomSeed > 0) {
            seedVal <- ceiling(stats::runif(1,min=10,max=100000000))
        }
        else {
            seedVal <- 0
        }
        gatingLocs <- cppGrowAnnotationForest(dataSet,
                                              as.double(pValueThreshold),
                                              as.integer(minimumClusterSize),
                                              allowRepeatedSplitting,
                                              maximumSearchDepth,
                                              maximumGatingNum,
                                              getDebugInfo,
                                              maximumAntimodeNumber,
                                              randomCandidateSearch,
                                              numberOfThreads,
                                              anyValueRestricted,
                                              resValMatrix,
                                              as.integer((cutPointUpperBound+2)), #add two for c++ representation
                                              maximumSearchTime,
                                              gaussianScaleParameter,
                                              seedVal,
                                              subSamplingThreshold,
                                              subSampleSize,
                                              subSampleIter,
                                              recordCounts,
                                              recordIndices)
        if (firstIteration) {
            gatingForest <- gatingLocs
            firstIteration <- FALSE
        }
        else {
            for (i in seq(length(gatingForest[["gateData"]]))) {
                gatingForest[["gateData"]][[i]] <- append(gatingForest[["gateData"]][[i]],
                                                          gatingLocs[["gateData"]][[i]])
            }
            gatingForest[["subsetCounts"]] <-  gatingForest[["subsetCounts"]] + gatingLocs[["subsetCounts"]]
            gatingForest[["subsetDenom"]] <-  gatingForest[["subsetDenom"]] + gatingLocs[["subsetDenom"]]
            for (i in seq(length(gatingForest[["indexData"]]))) {
                gatingForest[["indexData"]][[i]] <- append(gatingForest[["indexData"]][[i]],
                                                           gatingLocs[["indexData"]][[i]])
            }
            for (i in seq(length(gatingForest[["indexDepthData"]]))) {
                gatingForest[["indexDepthData"]][[i]] <- append(gatingForest[["indexDepthData"]][[i]],
                                                                gatingLocs[["indexDepthData"]][[i]])
            }
        }
        #decrement the number of iterations and compute time elapsed.
        remainingIterations <- (remainingIterations - 1)
        timeDiff <- proc.time()-startTime
        elapsedTime <- as.numeric(timeDiff[3])
    }
    #print(paste("Completed ", (numberIterations-remainingIterations), " iterations.",sep=""))
    afListEntries <- c("cutPoints","numCuts","cutDepth","nodePathScore","nodePopSize")
    finalAnnotation <- c()
    for (anColNum in seq(length(annotationVec))) {
        descUpdate <- paste0(annotationVec[anColNum],"_",afListEntries)
        finalAnnotation <- append(finalAnnotation,descUpdate)
    }
    names(gatingForest[["gateData"]]) <- finalAnnotation
    colnames(gatingForest[["subsetCounts"]]) <- annotationVec
    names(gatingForest[["subsetDenom"]]) <- annotationVec
    names(gatingForest[["indexData"]]) <- annotationVec
    names(gatingForest[["indexDepthData"]]) <- annotationVec
    return(gatingForest)
}


.nfGetEmpiricalDepthCounts <- function(maxDepth,annotationForest)
{
    #count the number of times a marker is cut at each possible depth
    depthCounts <- rep(0,maxDepth)
    names(depthCounts) <- seq(maxDepth)
    for (channelNum in seq(1,length(annotationForest),by=5)) {
        channelName <- names(annotationForest)[[channelNum]]
        #trim strings that can be appended to channel name in the c++.
        channelName <- gsub("_cutPoints","",channelName)
        channelName <- gsub("_numCuts","",channelName)
        channelName <- gsub("_cutDepth","",channelName)
        channelName <- gsub("_nodePathScore","",channelName)
        channelName <- gsub("_nodePopSize","",channelName)
        channelCuts <- annotationForest[[paste0(channelName,"_numCuts")]]
        uniqCuts <- sort(unique(channelCuts))
        if (length(uniqCuts)>0) {
            channelDepths <- annotationForest[[paste0(channelName,"_cutDepth")]]
            for (cutNum in uniqCuts) {
                #the c convention: depth number is repeated in the number of 
                #cutpoints times in the annotation forest.
                #need to lookup up the subCuts to prevent over counting
                cutLookups <- which(channelCuts == cutNum)
                subCuts <- cutLookups[seq(1,length(cutLookups),by=cutNum)]
                currentDepths <- channelDepths[subCuts]
                for (cDepthNum in seq(maxDepth)) {
                    depthCounts[[cDepthNum]] <-  (depthCounts[[cDepthNum]] + length(which(currentDepths == cDepthNum)))
                }
            }
        }
    }
    return(depthCounts)
}

.nfGetScoreListForChannel <- function(channel,annotationForest,eChannelSize,depthNorm,uniqNumCuts)
{
    nodeScoreList <- list()
    for (cpNum in uniqNumCuts) {
        #in addition to the empirical depth penalty,                                                                                                                                                            
        #a node is penalized by the cumulative product of (1-dipTestPvalue)                                                                                                                                            
        #along the path that led there. it also is penalized by the proportion                                                                                                                                         
        #of the nodes parent population to the root population in the forest.                                                                                                                                          
        allIndex <- which(annotationForest[[paste0(channel,"_numCuts")]]==cpNum)
        weightLookups <- allIndex[seq(1,length(allIndex),by=cpNum)]
        nodeSizes <- annotationForest[[paste0(channel,"_nodePopSize")]][weightLookups]
        popWeights <- nodeSizes/eChannelSize
        nodeDepths <- annotationForest[[paste0(channel,"_cutDepth")]][weightLookups]
        depthWeights <- depthNorm[nodeDepths]
        nodePathScores <- annotationForest[[paste0(channel,"_nodePathScore")]][weightLookups]
        nodeScores <- nodePathScores*popWeights*depthWeights
        nodeScoreList <- append(nodeScoreList,list(nodeScores))
        names(nodeScoreList)[length(nodeScoreList)] <- cpNum
    }
    return(nodeScoreList)
}


.nfParseAnnotationForest <- function(annotationForest,effectiveChannelSizes) {
    channelStrPrep <- names(annotationForest)[seq(from=1,to=length(annotationForest),by=5)]
    allChannels <- as.character(sapply(channelStrPrep,function(x){gsub("_cutPoints","",x)}))
    channelDataList <- list()
    #if a channel is never cut, slot assigned -Inf                                                                                                                                                                             
    channelDepths <- lapply(allChannels,function(x){sort(unique(annotationForest[[paste0(x,"_cutDepth")]]))})
    maxDepth <- suppressWarnings(max(unlist(lapply(channelDepths,function(x){max(x)}))))
    if (maxDepth < 0) {
        #the annotationForest is empty. return a null parse.
        for (channel in allChannels) {
            channelData <- list(NA,NA)
            names(channelData) <- c("channelScore","gates")
            channelDataList <- append(channelDataList,list(channelData))
            names(channelDataList)[length(channelDataList)] <- channel
        }
        return(channelDataList) 
    }
    depthCounts <- .nfGetEmpiricalDepthCounts(
        maxDepth=maxDepth,
        annotationForest=annotationForest
    )
    #each depth of the tree is normalized to sum to one with the empical counts                                                     
    depthNorm <- 1/depthCounts
    for (channel in allChannels) {
        #eChannelSize is the number of active cells in a channel that were used to estimate the density.
        eChannelSize <- effectiveChannelSizes[[channel]]
        uniqNumCuts <- unique(annotationForest[[paste0(channel,"_numCuts")]])
        if (length(uniqNumCuts) > 0) {
            nodeScoreList <- .nfGetScoreListForChannel(
                channel=channel,
                annotationForest=annotationForest,
                eChannelSize=eChannelSize,
                depthNorm=depthNorm,
                uniqNumCuts=uniqNumCuts
            )
            cutScores <- unlist(lapply(nodeScoreList,sum))
            channelScore <- sum(cutScores)
            if (channelScore > 0) {
                bestCutPointScore <- max(cutScores)
                cutPointSelection <- names(which(cutScores==bestCutPointScore))[1] #if tied channels, pick min
                nodeWeights <- nodeScoreList[[cutPointSelection]]/sum(nodeScoreList[[cutPointSelection]])
                selNumCuts <- as.numeric(cutPointSelection)
                selIndex <- which(annotationForest[[paste0(channel,"_numCuts")]]==selNumCuts)
                gates <- c()
                for (cutNum in seq(as.numeric(cutPointSelection))) {
                    gateLookups <- selIndex[seq(cutNum,length(selIndex),by=selNumCuts)]
                    gateLocations <- annotationForest[[paste0(channel,"_cutPoints")]][gateLookups]
                    gateLocation <- stats::weighted.mean(gateLocations,nodeWeights)
                    gates <- append(gates,gateLocation)
                }
                channelData <- list(channelScore,gates)
            }
            else {
                channelData <- list(0,NA)
            }
        }
        else {
            channelData <- list(0,NA)
        }
        names(channelData) <- c("channelScore","gates")
        channelDataList <- append(channelDataList,list(channelData))
        names(channelDataList)[length(channelDataList)] <- channel
    }
    #normalize scores to one
    maxChannelScore <- max(unlist(lapply(channelDataList,function(x){x$channelScore})))
    for (i in seq(length(channelDataList))) {
        channelDataList[[i]]$channelScore <- ((channelDataList[[i]]$channelScore)/maxChannelScore)
    }
    return(channelDataList)
}

