singleFaust <- function(dataSet,resFlag,resMat,minSize,threadNum,debugFlag,seedValue=123) {
    annF <- growAnnotationForest(dataSet=dataSet,
                                 numberIterations=1,
                                 pValueThreshold=0.25,
                                 minimumClusterSize=25,
                                 randomCandidateSearch=FALSE,
                                 maximumSearchDepth=2,
                                 numberOfThreads=threadNum,
                                 maximumGatingNum=1e10,
                                 anyValueRestricted=resFlag,
                                 resValMatrix=resMat,
                                 cutPointUpperBound=2,
                                 getDebugInfo=debugFlag,
                                 randomSeed=seedValue,
                                 subSamplingThreshold=200000,
                                 subSampleSize=100000,
                                 subSampleIter=1,
                                 recordCounts=FALSE)
    ePop <- apply(resMat,2,function(x){length(which(x==0))})
    names(ePop) <- colnames(dataSet)
    af <- annF[["gateData"]]
    pAnnF <- .parseAnnotationForest(af,ePop)
    forestScores <- unlist(lapply(pAnnF,function(x){x$channelScore}))
    firstDepth <- unlist(lapply(seq(3,length(af),by=5),
                                function(x){ifelse(length(af[[x]])==0,Inf,min(af[[x]]))}))
    names(firstDepth) <- names(forestScores)
    scoreNames <- names(which(forestScores >= 0.01))
    depthNames <- names(which(firstDepth <= 2))
    selectedNames <- intersect(scoreNames,depthNames)
    outScore <- forestScores[selectedNames]
    outNames <- names(sort(outScore,decreasing=TRUE))
    annMat <- matrix(1,nrow=nrow(dataSet),ncol=ncol(dataSet))
    colnames(annMat) <- colnames(dataSet)
    for (cNum in seq(length(outNames))) {
        cName <- outNames[cNum]
        gates <- pAnnF[[cName]]$gates
        for (gate in gates) {
            gateLookup <- which(dataSet[,cName] >= gate)
            if (length(gateLookup)) {
                annMat[gateLookup,cName] <- (annMat[gateLookup,cName] + 1)
            }
        }
    }
    firstName <- outNames[1]
    firstGates <- pAnnF[[firstName]]$gates
    firstAgNum <- length(firstGates) + 1
    partitionVector <- paste0(firstName,"_",annMat[,firstName],"_",firstAgNum)
    for (cNum in seq(2,length(outNames))) {
        cName <- outNames[cNum]
        partition <- table(partitionVector)
        updateNames <- names(which(partition >= minSize))
        if (length(updateNames)) {
            for (rootName in updateNames) {
                rootLookup <- which(partitionVector==rootName)
                gates <- pAnnF[[cName]]$gates
                agNum <- length(gates) + 1
                newNames <- paste0(rootName,"_",cName,"_",annMat[rootLookup,cName],"_",agNum)
                if (max(table(newNames)) >= minSize) { 
                    partitionVector[rootLookup] <- newNames
                }
            }
        }
    }
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_1_2_","- ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_2_2_","+ ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_1_3_","- ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_2_3_"," Medium ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_3_3_","+ ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_1_4_","- ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_2_4_"," MediumLow ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_3_4_"," MediumHigh ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_4_4_","+ ",x)}))

    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_1_2","- ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_2_2","+ ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_1_3","- ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_2_3"," Medium ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_3_3","+ ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_1_4","- ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_2_4"," MediumLow ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_3_4"," MediumHigh ",x)}))
    partitionVector <- as.character(sapply(partitionVector,function(x){gsub("_4_4","+ ",x)}))
    return(partitionVector)
}
