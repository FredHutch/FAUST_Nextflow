nf_step_10_plot_sample_histograms <- function(
                                              sampleName,
                                              startingCellPop
                                              )
{
    analysisMap <- readRDS("analysisMap.rds")
    resList <- readRDS(paste0(startingCellPop,"_resList.rds"))
    selC <- readRDS(paste0(startingCellPop,"_selectedChannels.rds"))

    exprsMat <- readRDS(paste0(sampleName,"_exprsMat.rds"))
    aLevel <- analysisMap[which(analysisMap[,"sampleName"]==sampleName),"analysisLevel"]
    plotList <- list()
    for (channel in selC) {
        channelData <- as.data.frame(exprsMat[,channel,drop=FALSE])
        colnames(channelData) <- "x"
        gateData <- resList[[channel]][[aLevel]]
        channelQs <- as.numeric(quantile(channelData$x,probs=c(0.01,0.99)))
        histLookupLow <- which(channelData$x >= channelQs[1])
        histLookupHigh <- which(channelData$x <= channelQs[2])
        histLookup <- intersect(histLookupLow,histLookupHigh)
        histData <- channelData[histLookup,"x",drop=FALSE]
        p <- .nfGetHistogram(histData,channel,gateData)
        plotList <- append(plotList,list(p))
    }
    pOut <- cowplot::plot_grid(plotlist=plotList)
    cowplot::save_plot(paste0(sampleName,".pdf"),
              pOut,
              base_height = (5*ceiling(sqrt(length(selC)))),
              base_width = (5*ceiling(sqrt(length(selC)))))
    return()
}

.nfGetHistogram <- function(histData,channelName,gates) {
    fdBreaks <- pretty(range(histData[,"x"]),
                     n = grDevices::nclass.FD(histData[,"x"]), min.n = 1)
    binWidth <- fdBreaks[2]-fdBreaks[1]
    p <- ggplot(histData,aes(x=x)) +
        geom_histogram(binwidth=binWidth) +
        theme_bw()+
        geom_vline(xintercept=gates,color="red",linetype="dashed")+
        ggtitle(channelName)
    return(p)
}

