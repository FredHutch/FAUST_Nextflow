nf_step_11_discover_populations_for_unit<- function(
                                                    experimentalUnit,
                                                    startingCellPop, 
                                                    nameOccuranceNum,
                                                    threadNumber
                                                    )
{
    selectedChannels <- readRDS(paste0(startingCellPop,"_selectedChannels.rds"))
    analysisMap <- readRDS("analysisMap.rds")
    resList <- readRDS(paste0(startingCellPop,"_resList.rds"))

    levelExprs <- readRDS(paste0(experimentalUnit,"_levelExprs.rds"))
    levelRes <- readRDS(paste0(experimentalUnit,"_levelRes.rds"))
    levelExprs <- levelExprs[,selectedChannels, drop = FALSE]
    levelRes <- levelRes[,selectedChannels, drop = FALSE]
    resFlag <- FALSE
    for (colNum in seq(ncol(levelRes))) {
        if (length(which(levelRes[,colNum] > 0))) {
            resFlag <- TRUE
            break
        }
    }
    #get the scamp annotation forest
    scampAF <- rep(list(NA),ncol(levelExprs))
    names(scampAF) <- colnames(levelExprs)
    for (colName in colnames(levelExprs)) {
        scampAF[[colName]] <- resList[[colName]][[experimentalUnit]]
    }
    scampClustering <- scamp(
        dataSet = levelExprs,
        numberIterations = 1,
        minimumClusterSize = 25,
        numberOfThreads = threadNumber,
        anyValueRestricted = resFlag,
        resValMatrix = levelRes,
        useAnnForest = TRUE,
        annForestVals = scampAF,
        randomSeed=12345,
        getDebugInfo = FALSE,
        subSampleThreshold = 500001,
        subSampleSize = 500000,
        subSampleIterations = 1
    )
    runClustering <- scampClustering[[1]]
    maxClustering <- scampClustering[[2]]
    outClustering <- rep("Uncertain",length(maxClustering))
    agreeIndex <- which(runClustering==maxClustering)
    outClustering[agreeIndex] <- maxClustering[agreeIndex]
    clusterNames <- setdiff(sort(unique(names(table(outClustering)))),"Uncertain")
    saveRDS(clusterNames,paste0(experimentalUnit,"_scampClusterLabels.rds"))
    #unwind the level to each sample
    levelLookup <- readRDS(paste0(experimentalUnit,"_levelLookup.rds"))
    for (sampleName in names(table(levelLookup))) {
        sampleLookup <- which(levelLookup == sampleName)
        if (length(sampleLookup)) {
            sampleClustering <- outClustering[sampleLookup]
            data.table::fwrite(list(sampleClustering),
                               file = paste0(sampleName,"_scampAnnotation.csv"),
                               sep = "`",
                               append = FALSE,
                               row.names = FALSE,
                               col.names = FALSE,
                               quote = FALSE)
        }
    }
    return()
}
