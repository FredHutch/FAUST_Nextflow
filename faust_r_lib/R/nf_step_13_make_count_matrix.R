nf_step_13_make_count_matrix <- function(
                                         startingCellPop
                                         )
{
    selectedChannels <- readRDS(paste0(startingCellPop,"_selectedChannels.rds"))
    analysisMap <- readRDS("analysisMap.rds")
    faustClusterNames <- readRDS("scampClusterNames.rds")
    faustClusterNames <- append(faustClusterNames,"0_0_0_0_0")
    activeSamples <- analysisMap[,"sampleName"]
    faustCountMatrix <- matrix(0,nrow=length(activeSamples),ncol=length(faustClusterNames))
    rownames(faustCountMatrix) <- activeSamples
    colnames(faustCountMatrix) <- faustClusterNames
    for (sampleName in activeSamples) {
        sNum <- which(rownames(faustCountMatrix)==sampleName)
        sAnn <- utils::read.table(file=paste0(sampleName,"_faustAnnotation.csv"),
                           header=F,sep="`",
                           stringsAsFactors=FALSE)[,1]
        for (colName in colnames(faustCountMatrix)) {
            faustCountMatrix[sNum,colName] <- length(which(sAnn==colName))
        }
    }
    #pretty print the column names
    #save the original encoding for ploting gating strategies.
    newColNames <- faustColNames <- colnames(faustCountMatrix)
    newColNames <- as.character(sapply(newColNames,function(x){gsub("~1~[[:digit:]]~","-",x)}))
    newColNames <- as.character(sapply(newColNames,function(x){gsub("~2~2~","+",x)}))
    newColNames <- as.character(sapply(newColNames,function(x){gsub("~3~3~","Bright",x)}))
    newColNames <- as.character(sapply(newColNames,function(x){gsub("~4~4~","+",x)}))
    newColNames <- as.character(sapply(newColNames,function(x){gsub("~2~3~","Dim",x)}))
    newColNames <- as.character(sapply(newColNames,function(x){gsub("~2~4~","Med-",x)}))
    newColNames <- as.character(sapply(newColNames,function(x){gsub("~3~4~","Med+",x)}))
    colNameMap <- data.frame(faustColNames=faustColNames,
                             newColNames=newColNames,
                             stringsAsFactors=FALSE)
    colnames(faustCountMatrix) <- newColNames
    saveRDS(colNameMap,paste0("colNameMap.rds"))
    saveRDS(faustCountMatrix,paste0("faustCountMatrix.rds"))
    return()
}
