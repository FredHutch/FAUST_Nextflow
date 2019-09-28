nf_step_05_select_channels <- function(
                                       startingCellPop,
                                       depthScoreThreshold,
                                       selectionQuantile
                                       )
{
    analysisMap <- readRDS("analysisMap.rds")
    uniqueLevels <- unique(analysisMap[,"analysisLevel"])
    firstForest <- TRUE
    for (aLevel in uniqueLevels) {
        if (file.exists(paste0(aLevel,"_",startingCellPop,"_pAnnF.rds"))) {
            afIn <- readRDS(paste0(aLevel,"_",startingCellPop,"_pAnnF.rds"))
            forestScores <- unlist(lapply(afIn,function(x){x$channelScore}))
            rafIn <- readRDS(paste0(aLevel,"_",startingCellPop,"_annF.rds"))
            gd <- rafIn[["gateData"]]
            firstDepth <- unlist(lapply(seq(3,length(gd),by=5),
                                        function(x){ifelse(length(gd[[x]])==0,Inf,min(gd[[x]]))}))
            names(firstDepth) <- names(forestScores)
            if (firstForest) {
                depthMat <- scoreMat <- matrix(nrow=0,ncol=length(forestScores))
                colnames(scoreMat) <- names(forestScores)
                colnames(depthMat) <- names(forestScores)
                firstForest <- FALSE
            }
            scoreMat <- rbind(scoreMat,forestScores)
            rownames(scoreMat)[length(rownames(scoreMat))] <- aLevel
            depthMat <- rbind(depthMat,firstDepth)
            rownames(depthMat)[length(rownames(depthMat))] <- aLevel
        }
        else {
            print(paste0("No parsed forest detected at aLevel: ",aLevel))
        }
    }
    for (column in colnames(scoreMat)) {
        naLookup <- which(is.na(scoreMat[,column]))
        if (length(naLookup)) {
            scoreMat[naLookup,column] <- 0
        }
    }
    saveRDS(scoreMat,"scoreMat.rds")
    saveRDS(depthMat,"depthMat.rds")
    quantileScore <- apply(scoreMat,2,function(x){as.numeric(quantile(x,probs=c(selectionQuantile)))})
    scoreNames <- names(which(quantileScore >= depthScoreThreshold))
    quantileDepth <- apply(depthMat,2,function(x){as.numeric(quantile(x,probs=c((1-selectionQuantile))))})
    depthNames <- names(which(quantileDepth <= 2))
    selectedNames <- scoreNames 
    outScore <- quantileScore[selectedNames]
    outNames <- names(sort(outScore,decreasing=TRUE))
    saveRDS(outNames,"initSelC.rds")
    return()
}
