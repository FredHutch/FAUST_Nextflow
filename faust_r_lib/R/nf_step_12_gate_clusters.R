nf_step_12_gate_clusters <- function(
                                     startingCellPop,
                                     nameOccuranceNum
                                     )
{
    #collect all labels from the scamp clusterings
    analysisMap <- readRDS("analysisMap.rds")
    allExperimentalUnits <- unique(gsub("_scampClusterLabels\\.rds","",list.files(pattern="*_scampClusterLabels.rds")))
    clusterNames <- c()
    for (analysisLevel in allExperimentalUnits) {
        if (!file.exists(paste0(analysisLevel,"_scampClusterLabels.rds"))) {
            print(paste0("Labels not detected in analysisLevel ",analysisLevel))
            print("This is a bug -- all analysis levels should have labels.")
            stop("Killing FAUST. Check logs to determine which level is unlabeled.")
        }
        else {
            levelLabels <- readRDS(paste0(analysisLevel,"_scampClusterLabels.rds"))
            clusterNames <- append(clusterNames,levelLabels)
        }
    }
    nameSummary <- table(clusterNames)
    saveRDS(nameSummary,"scampNameSummary.rds")
    clusterNames <- names(nameSummary[which(nameSummary >= nameOccuranceNum)])
    saveRDS(clusterNames,"scampClusterNames.rds")
    nameSummaryPlotDF <- data.frame(x=seq(max(nameSummary)),
                                    y=sapply(seq(max(nameSummary)),function(x){
                                        length(which(nameSummary >= x))}))
    nspOut <- ggplot(nameSummaryPlotDF,aes(x=x,y=y))+
        geom_line()+
        theme_bw()+
        geom_vline(xintercept=nameOccuranceNum,col="red")+
        xlab("Number of times a cluster name appears across SCAMP clusterings")+
        ylab("Number of SCAMP clusters >= the appearance number")+
        ggtitle("Red line is nameOccuranceNum setting in faust")
    cowplot::save_plot("scampNamesPlot.pdf",
                       nspOut,base_height=15,base_width=15)

    #
    #prepend the scamp cluster accumulation
    #
    
    selectedChannels <- readRDS(paste0(startingCellPop,"_selectedChannels.rds"))
    analysisMap <- readRDS("analysisMap.rds")
    resList <- readRDS(paste0(startingCellPop,"_resList.rds"))
    activeSamples <- analysisMap[,"sampleName"]
    scampCellPops <- readRDS(paste0("scampClusterNames.rds"))
    for (sampleName in activeSamples) {
        sAnn <- utils::read.table(file = paste0(sampleName,"_scampAnnotation.csv"),
                                  header = FALSE, sep = "`", 
                                  stringsAsFactors = FALSE)[,1]
        annotationMatrix <- utils::read.table(file = paste0(sampleName,"_annotationMatrix.csv"),
                                       header = FALSE,
                                       sep = ",",
                                       stringsAsFactors = FALSE)
        colnames(annotationMatrix) <- selectedChannels
        if (!(length(sAnn) == nrow(annotationMatrix))) {
            print(paste0("Annotation matrix doesn't match scamp annotation in ", sampleName))
            stop("Investigate.")
        }
        aLevel <- analysisMap[which(analysisMap[,"sampleName"] == sampleName), "analysisLevel"]
        scampAF <- rep(list(NA),length(selectedChannels))
        names(scampAF) <- selectedChannels
        for (channel in selectedChannels) {
            scampAF[[channel]] <- resList[[channel]][[aLevel]]
        }
        gateNums <- unlist(lapply(scampAF,length)) + 1
        exactPartition <- gateSample(as.matrix(annotationMatrix), selectedChannels, gateNums, scampCellPops);
        data.table::fwrite(
                        list(exactPartition),
                        file = paste0( sampleName, "_faustAnnotation.csv"),
                        sep = "~",
                        append = FALSE,
                        row.names = FALSE,
                        col.names = FALSE,
                        quote = FALSE
                    )
    }
    return()

}
