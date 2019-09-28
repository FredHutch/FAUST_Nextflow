nf_step_01_extract_data_from_gs <- function(
                                            gatingSetPath,
                                            activeChannelsPath,
                                            startingCellPop
                                            )
{
    activeChannels <- readRDS(activeChannelsPath)
    gs <- load_gs(gatingSetPath)
    samplesInGS <- flowWorkspace::sampleNames(gs)
    for (sampleName in samplesInGS) {
        dataSet <- flowWorkspace::getData(gs[[sampleName]],startingCellPop)
        exprsMatIn <- flowCore::exprs(dataSet)
        markers <- Biobase::pData(flowCore::parameters(dataSet))
        colnames(exprsMatIn) <- as.vector(markers[match(colnames(exprsMatIn),markers[,"name"], nomatch=0),]$desc)
        exprsMat <- exprsMatIn[,activeChannels,drop=FALSE]
        saveRDS(exprsMat,paste0(sampleName,"_exprsMat.rds"))#nolint
    }
    return()
}    
