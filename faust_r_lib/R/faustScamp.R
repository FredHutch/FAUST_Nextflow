faustScamp <- function(dataSet,
                       resFlag=FALSE,
                       resMat=matrix(0,nrow=2,ncol=2),
                       threadNum=1,
                       debugFlag=FALSE,
                       seedValue=123,
                       iterNum=1,
                       scoreThreshold=0.05,
                       pValueThreshold=0.25,
                       maximumSearchDepth = 2) {
  annF <- growAnnotationForest(
      dataSet = dataSet,
      numberIterations = iterNum,
      pValueThreshold = 0.25,
      minimumClusterSize = 25,
      randomCandidateSearch = FALSE,
      maximumSearchDepth = maximumSearchDepth,
      numberOfThreads = threadNum,
      maximumGatingNum = 1e10,
      anyValueRestricted = resFlag,
      resValMatrix = resMat,
      cutPointUpperBound = 2,
      getDebugInfo = debugFlag,
      randomSeed = seedValue,
      subSamplingThreshold = 200000,
      subSampleSize = 100000,
      subSampleIter = 1,
      recordCounts = FALSE,
      recordIndices = FALSE
  )
  if (resFlag) {
      ePop <- apply(resMat,2,function(x){length(which(x==0))})
      names(ePop) <- colnames(dataSet)
  }
  else {
      resMat <- matrix(0,nrow=nrow(dataSet),ncol=ncol(dataSet))
      colnames(resMat) <- colnames(dataSet)
      ePop <- apply(resMat,2,function(x){length(which(x==0))})
      names(ePop) <- colnames(dataSet)
  }
  af <- annF[["gateData"]]
  pAnnF <- .parseAnnotationForest(af,ePop)
  forestScores <- unlist(lapply(pAnnF,function(x){x$channelScore}))
  selectedNames <- names(which(forestScores >= scoreThreshold))
  outScore <- forestScores[selectedNames]
  outNames <- names(sort(outScore,decreasing=TRUE))
  if (length(outNames)) {
      subDataSet <- dataSet[,outNames,drop=FALSE]
      subResMat <- resMat[,outNames,drop=FALSE]
      scampAF <- rep(list(NA),ncol(subDataSet))
      names(scampAF) <- colnames(subDataSet)
      for (colName in outNames) {
          scampAF[[colName]] <- pAnnF[[colName]][["gates"]]
      }
      annotationMatrix <- matrix(0,nrow=nrow(subDataSet),ncol=ncol(subDataSet))
      colnames(annotationMatrix) <- colnames(subDataSet)
      for (column in names(scampAF)) {
          annotationMatrix[,column] <- 1
          gateVals <- scampAF[[column]]
          if (is.list(gateVals)) {
              gateVals <- as.vector(unlist(gateVals))
          }
          for (gateVal in gateVals) {
              annLook <- which(subDataSet[,column] >= gateVal)
              if (length(annLook)) {
                  annotationMatrix[annLook,column] <- (annotationMatrix[annLook,column]+1)
              }
          }
      }
      scampClustering <- scamp::scamp(
                                    dataSet=subDataSet,
                                    numberIterations=iterNum,
                                    pValueThreshold=pValueThreshold,
                                    numberOfThreads=threadNum,
                                    anyValueRestricted=resFlag,
                                    resValMatrix=subResMat,
                                    useAnnForest = TRUE,
                                    annForestVals = scampAF,
                                    getDebugInfo = debugFlag
                                )
      selectedChannels <- names(scampAF)
      sAnn <- scampClustering[[2]]
      scampCellPops <- names(table(sAnn))
      gateNums <- unlist(lapply(scampAF,length))+1
      exactPartition <- rep("0_0_0_0_0",nrow(annotationMatrix))
      for (rowNum in seq(nrow(annotationMatrix))) {
          ep <- paste0(paste0(paste0(selectedChannels,"~",annotationMatrix[rowNum,]),"~",gateNums,"~"),collapse="")
          #if (ep %in% scampCellPops) {
          exactPartition[rowNum] <- ep
          #}
      }
      outList <- rep(list(NA),4)
      names(outList) <- c("faustLabels","scampLabels","annF","pAnnF")
      outList[["faustLabels"]] <- exactPartition
      outList[["scampLabels"]] <- sAnn
      outList[["annF"]] <- scampAF
      outList[["pAnnF"]] <- pAnnF
      return(outList)
  }
  else {
      vacuousCluster <- rep("noClustersFound",nrow(dataSet))
      return(vacuousCluster)
  }
}


