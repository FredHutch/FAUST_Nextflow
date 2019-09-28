nf_step_03_make_experimental_units <- function()
{
    analysisMap <- readRDS("analysisMap.rds")
    uniqueLevels <- unique(analysisMap[,"analysisLevel"])
    for (aLevel in uniqueLevels) {
        aData <- analysisMap[which(analysisMap[,"analysisLevel"]==aLevel),,drop=FALSE]
        firstSample <- TRUE
        for (sampleNum in seq(nrow(aData))) {
            sampleName <- aData[sampleNum,"sampleName"]
            if (firstSample) {
                levelExprs <- readRDS(paste0(sampleName,"_exprsMat.rds"))
                levelRes <- readRDS(paste0(sampleName,"_resMat.rds"))
                levelLookup <- rep(sampleName,nrow(levelExprs))
                firstSample <- FALSE
            }
            else {
                newExprs <- readRDS(paste0(sampleName,"_exprsMat.rds"))
                levelExprs <- rbind(levelExprs,newExprs)
                newRes <- readRDS(paste0(sampleName,"_resMat.rds"))
                levelRes <- rbind(levelRes,newRes)
                newLookup <- rep(sampleName,nrow(newExprs))
                levelLookup <- append(levelLookup,newLookup)
            }
        }
        if (nrow(levelExprs)) { #there is data associated with the analysis level. record it.
            saveRDS(levelExprs,paste0(aLevel,"_levelExprs.rds"))
            saveRDS(levelRes,paste0(aLevel,"_levelRes.rds"))
            saveRDS(levelLookup,paste0(aLevel,"_levelLookup.rds"))
        }
    }
    return()
}
