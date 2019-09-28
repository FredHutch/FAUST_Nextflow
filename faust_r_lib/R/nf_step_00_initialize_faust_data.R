nf_step_00_initialize_faust_data <- function(
                                             gatingSetPath,
                                             experimentalUnit,
                                             imputationHierarchy
                                             )
{
    gs <- load_gs(gatingSetPath)
    gspData <- pData(gs)
    analysisMap <- data.frame(
        sampleName = sampleNames(gs),
        analysisLevel = gspData[,experimentalUnit,drop=TRUE],
        stringsAsFactors = FALSE
    )
    analysisMap$impH <- as.character(gspData[,imputationHierarchy,drop=TRUE])
    saveRDS(analysisMap,"analysisMap.rds")
    return()
}
