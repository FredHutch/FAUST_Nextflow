nf_step_07_make_annotation_matrices <- function(startingCellPop)
{
    analysisMap <- readRDS("analysisMap.rds")
    resList <- readRDS(paste0(startingCellPop,"_resList.rds"))
    selC <- readRDS(paste0(startingCellPop,"_selectedChannels.rds"))
    for (sampleNum in seq(nrow(analysisMap))) {
        sampleName <- analysisMap[sampleNum,"sampleName"]
        aLevel <- analysisMap[sampleNum,"analysisLevel"]
        exprsMatIn <- readRDS(paste0(sampleName,"_exprsMat.rds"))
        exprsMat <- exprsMatIn[,selC,drop=FALSE]
        annotationMatrix <- matrix(0,nrow=nrow(exprsMat),ncol=ncol(exprsMat))
        colnames(annotationMatrix) <- colnames(exprsMat)
        for (column in names(resList)) {
            annotationMatrix[,column] <- 1
            gateVals <- resList[[column]][[aLevel]]
            if (is.list(gateVals)) {
                gateVals <- as.vector(unlist(gateVals))
            }
            for (gateVal in gateVals) {
                annLook <- which(exprsMat[,column] >= gateVal)
                if (length(annLook)) {
                    annotationMatrix[annLook,column] <- (annotationMatrix[annLook,column]+1)
                }
            }
        }
        data.table::fwrite(as.data.frame(annotationMatrix),
                    file=paste0(sampleName,
                                "_annotationMatrix.csv"),
                    sep=",",row.names=FALSE,col.names=FALSE)
    }
    return()
}
