.clusterALevelWithScamp <- function(aLevel,
                                    resList,
                                    selectedChannels,
                                    numScampIter,
                                    debugFlag,
                                    threadNum,
                                    seedValue,
                                    projectPath,
                                    densitySubSampleThreshold,
                                    densitySubSampleSize,
                                    densitySubSampleIterations,
                                    archDescriptionList
                                    )
{
    if (debugFlag) print(paste0("Starting SCAMP for: ",aLevel))
    levelExprs <- readRDS(paste0(projectPath,"/faustData/levelData/",aLevel,"/levelExprs.rds"))
    levelRes <- readRDS(paste0(projectPath,"/faustData/levelData/",aLevel,"/levelRes.rds"))
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
        scampAF[[colName]] <- resList[[colName]][[aLevel]]
    }
    scampClustering <- scamp(
        dataSet = levelExprs,
        numberIterations = numScampIter,
        minimumClusterSize = 25,
        numberOfThreads = threadNum,
        anyValueRestricted = resFlag,
        resValMatrix = levelRes,
        useAnnForest = TRUE,
        annForestVals = scampAF,
        randomSeed=seedValue,
        getDebugInfo = FALSE,
        subSampleThreshold = densitySubSampleThreshold,
        subSampleSize = densitySubSampleSize,
        subSampleIterations = densitySubSampleIterations
    )
    runClustering <- scampClustering[[1]]
    maxClustering <- scampClustering[[2]]
    outClustering <- rep("Uncertain",length(maxClustering))
    agreeIndex <- which(runClustering==maxClustering)
    if (length(agreeIndex)) {
        outClustering[agreeIndex] <- maxClustering[agreeIndex]
    }
    else {
        print(paste0("SCAMP reached no concensus for: ",aLevel))
        print("This indicates high-amount of uncertainty in cluster labels.")
        print("Increase the numScampIter parameters until concensus reached")
        stop("killing job.")
    }
    clusterNames <- setdiff(sort(unique(names(table(outClustering)))),"Uncertain")
    saveRDS(clusterNames,paste0(projectPath,"/faustData/levelData/",aLevel,"/scampClusterLabels.rds"))
    #unwind the level to each sample
    levelLookup <- readRDS(paste0(projectPath,"/faustData/levelData/",aLevel,"/levelLookup.rds"))
    for (sampleName in names(table(levelLookup))) {
        sampleLookup <- which(levelLookup == sampleName)
        if (length(sampleLookup)) {
            sampleClustering <- outClustering[sampleLookup]
            data.table::fwrite(list(sampleClustering),
                               file = paste0(projectPath,"/faustData/sampleData/",sampleName,"/scampAnnotation.csv"),
                               sep = "`",
                               append = FALSE,
                               row.names = FALSE,
                               col.names = FALSE,
                               quote = FALSE)
        }
    }
    scampALevelDone <- TRUE
    saveRDS(scampALevelDone,paste0(projectPath,"/faustData/levelData/",aLevel,"/scampALevelComplete.rds"))
    if (debugFlag) print(paste0("SCAMP complete for: ",aLevel))
    return()
}

                                    
.clusterLevelsWithScamp <- function(startingCellPop,
                                    selectedChannels,
                                    analysisMap,
                                    numScampIter,
                                    nameOccuranceNum,
                                    debugFlag,
                                    threadNum,
                                    seedValue,
                                    projectPath,
                                    densitySubSampleThreshold,
                                    densitySubSampleSize,
                                    densitySubSampleIterations,
                                    archDescriptionList
                                    )
{
    resList <- readRDS(paste0(projectPath,"/faustData/gateData/",startingCellPop,"_resList.rds"))
    uniqueLevels <- sort(unique(analysisMap[,"analysisLevel"]))
    activeLevels <- c()
    #accumulate vector of levels without annotation forests.
    for (analysisLevel in uniqueLevels) {
        if (!file.exists(paste0(projectPath,"/faustData/levelData/",analysisLevel,"/scampALevelComplete.rds"))) {
            activeLevels <- append(activeLevels,analysisLevel)
        }
    }
    #grow forests for levels that lack them
    if ((length(activeLevels)) && (archDescriptionList$targetArch=="singleCPU")) {
        while (length(activeLevels)) {
            currentLevel <- activeLevels[1]
            activeLevels <- activeLevels[-1]
            .clusterALevelWithScamp(
                aLevel=currentLevel,
                resList=resList,
                selectedChannels=selectedChannels,
                numScampIter=numScampIter,
                debugFlag=debugFlag,
                threadNum=threadNum,
                seedValue=seedValue,
                projectPath=projectPath,
                densitySubSampleThreshold=densitySubSampleThreshold,
                densitySubSampleSize=densitySubSampleSize,
                densitySubSampleIterations=densitySubSampleIterations,
                archDescriptionList=archDescriptionList
            )
        }
    }
    else if ((length(activeLevels)) && (archDescriptionList$targetArch=="slurmCluster")) {
        if (!dir.exists(paste0(projectPath,"/faustData/slurmScampData"))) {
            dir.create(paste0(projectPath,"/faustData/slurmScampData"))
        }
        stillRunningSlurm <- TRUE
        startSlurmTime <- proc.time()
        maxNodeNum <- archDescriptionList$maxNodeNum
        maxTime <- archDescriptionList$maxTime
        sbatchFlags <- archDescriptionList$sbatchFlags
        currentJobs <- 0
        jobNum <- 0
        slurmLevels <- c()
        while (stillRunningSlurm) {
            if ((currentJobs < maxNodeNum) && (length(activeLevels))) {
                jobNum <- jobNum + 1
                currentLevel <- activeLevels[1]
                activeLevels <- activeLevels[-1]
                currentJobs <- (currentJobs + 1)
                slurmLevels <- append(slurmLevels,currentLevel)
                if (!dir.exists(paste0(projectPath,"/faustData/slurmScampData/",currentLevel))) {
                    dir.create(paste0(projectPath,"/faustData/slurmScampData/",currentLevel))
                }
                .prepareSlurmScampJob(
                    aLevel=currentLevel,
                    startingCellPop=startingCellPop,
                    selectedChannels=selectedChannels,
                    numScampIter=numScampIter,
                    minClusterSize=25,
                    threadNum=archDescriptionList$nodeThreadNum,
                    seedValue=seedValue,
                    projectPath=projectPath,
                    densitySubSampleThreshold=densitySubSampleThreshold,
                    densitySubSampleSize=densitySubSampleSize,
                    densitySubSampleIterations=densitySubSampleIterations,
                    jobNumber = jobNum 
                )
                print(paste0("Slurm SCAMP clustering starting for ", currentLevel))
                launchJob <- system2("sbatch",
                                     args=paste0(sbatchFlags,
                                                 paste0(" '",projectPath,
                                                        "/faustData/slurmScampData/",
                                                        currentLevel,
                                                        "/slurmScampJob.sh","'")
                                                 ),
                                     stdout=TRUE)
            }
            else {
                Sys.sleep(10) #in seconds
                currentSlurmTime <- (proc.time() - startSlurmTime)
                if (as.numeric(currentSlurmTime[3]) > maxTime) {
                    print("Slurm SCAMP clustering exceeded max time.")
                    print("Check logs in /faustData/slurmScampData")
                    stop("Killing FAUST")
                }
                activeSlurmLevels <- c()
                for (sLevel in slurmLevels) {
                    if ((file.exists(paste0(projectPath,
                                            "/faustData/slurmScampData/",
                                            sLevel,
                                            "/slurmScampComplete.rds"))) &&
                        (readRDS(paste0(projectPath,
                                        "/faustData/slurmScampData/",
                                        sLevel,
                                        "/slurmScampComplete.rds"))))
                    {
                        print(paste0("Slurm SCAMP clustering complete for ", sLevel))
                        currentJobs <- (currentJobs - 1)
                    }
                    else {
                        activeSlurmLevels <- append(activeSlurmLevels,sLevel)
                    }
                }
                slurmLevels <- activeSlurmLevels
                if ((length(activeLevels)==0) && (currentJobs==0)) {
                    stillRunningSlurm <- FALSE
                }
            }
        }
    }
    else if (length(activeLevels)) {
        print("Unsupported targetArch requested in archDescriptionList.")
        stop("Killing FAUST.")
    }
    #collect all labels from the scamp clusterings
    if (debugFlag) print("Accumulating cluster labels.")
    clusterNames <- c()
    for (analysisLevel in uniqueLevels) {
        if (!file.exists(paste0(projectPath,"/faustData/levelData/",analysisLevel,"/scampClusterLabels.rds"))) {
            print(paste0("Labels not detected in analysisLevel ",analysisLevel))
            print("This is a bug -- all analysis levels should have labels.")
            stop("Killing FAUST. Check logs to determine which level is unlabeled.")
        }
        else {
            levelLabels <- readRDS(paste0(projectPath,"/faustData/levelData/",analysisLevel,"/scampClusterLabels.rds"))
            clusterNames <- append(clusterNames,levelLabels)
        }
    }
    nameSummary <- table(clusterNames)
    saveRDS(nameSummary,paste0(projectPath,"/faustData/metaData/scampNameSummary.rds"))
    clusterNames <- names(nameSummary[which(nameSummary >= nameOccuranceNum)])
    saveRDS(clusterNames,paste0(projectPath,"/faustData/metaData/scampClusterNames.rds"))
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
    cowplot::save_plot(paste0(projectPath,"/faustData/plotData/scampNamesPlot.pdf"),
                       nspOut,base_height=15,base_width=15)
    if (debugFlag) print("Cluster labels collected and saved.")
    return()
}

.prepareSlurmScampJob <- function(aLevel,
                                  startingCellPop,
                                  selectedChannels,
                                  numScampIter,
                                  minClusterSize,
                                  debugFlag,
                                  threadNum,
                                  seedValue,
                                  projectPath,
                                  densitySubSampleThreshold,
                                  densitySubSampleSize,
                                  densitySubSampleIterations,
                                  jobNumber
                                  )
{
    .programTemplate <-'library(scamp)
library(data.table)
levelExprs <- readRDS(paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/levelExprs.rds"))
levelRes <- readRDS(paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/levelRes.rds"))
resList <- readRDS(paste0({{projectPath}},"/faustData/gateData/",{{startingCellPop}},"_resList.rds"))
levelExprs <- levelExprs[,{{selectedChannels}}, drop = FALSE]
levelRes <- levelRes[,{{selectedChannels}}, drop = FALSE]
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
    scampAF[[colName]] <- resList[[colName]][[{{aLevel}}]]
}
scampClustering <- scamp::scamp(
    dataSet = levelExprs,
    numberIterations = {{numScampIter}},
    minimumClusterSize = {{minClusterSize}},
    numberOfThreads = {{threadNum}},
    anyValueRestricted = resFlag,
    resValMatrix = levelRes,
    useAnnForest = TRUE,
    annForestVals = scampAF,
    randomSeed={{seedValue}},
    getDebugInfo = FALSE,
    subSampleThreshold = {{densitySubSampleThreshold}},
    subSampleSize = {{densitySubSampleSize}},
    subSampleIterations = {{densitySubSampleIterations}}
)
runClustering <- scampClustering[[1]]
maxClustering <- scampClustering[[2]]
outClustering <- rep("Uncertain",length(maxClustering))
agreeIndex <- which(runClustering==maxClustering)
if (length(agreeIndex) == 0) {
   print(paste0("SCAMP reached no concensus for: ",aLevel))
   print("This indicates high-amount of uncertainty in cluster labels.")
   print("Increase the numScampIter parameters until concensus reached")
   stop("killing job.")
}
outClustering[agreeIndex] <- maxClustering[agreeIndex]
clusterNames <- setdiff(sort(unique(names(table(outClustering)))),"Uncertain")
saveRDS(clusterNames,paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/scampClusterLabels.rds"))
#unwind the level to each sample
levelLookup <- readRDS(paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/levelLookup.rds"))
for (sampleName in names(table(levelLookup))) {
    sampleLookup <- which(levelLookup == sampleName)
    if (length(sampleLookup)) {
        sampleClustering <- outClustering[sampleLookup]
        data.table::fwrite(
            list(sampleClustering),
            file = paste0({{projectPath}},"/faustData/sampleData/",sampleName,"/scampAnnotation.csv"),
            sep = "`",
            append = FALSE,
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)
    }
}
scampALevelDone <- TRUE
saveRDS(scampALevelDone,paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/scampALevelComplete.rds"))
slurmScampDone <- TRUE
saveRDS(slurmScampDone,paste0({{projectPath}},"/faustData/slurmScampData/",{{aLevel}},"/slurmScampComplete.rds"))
'
    programData <- list(
        aLevel=paste0("'",aLevel,"'"),
        startingCellPop=paste0("'",startingCellPop,"'"),
        selectedChannels=paste0("c('",paste0(selectedChannels,collapse="','"),"')"),
        numScampIter=numScampIter,
        minClusterSize=minClusterSize,
        threadNum=threadNum,
        seedValue=seedValue,
        projectPath=paste0("'",projectPath,"'"),
        densitySubSampleThreshold=densitySubSampleThreshold,
        densitySubSampleSize=densitySubSampleSize,
        densitySubSampleIterations=densitySubSampleIterations
    )
    renderedProgram <- whisker.render(.programTemplate, programData)
    write(renderedProgram,file=paste0(projectPath,"/faustData/slurmScampData/",aLevel,"/slurmScampJob.R"))
    .controlTemplate <-'#!/bin/bash
#SBATCH --partition=largenode
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task={{threadNum}}
#SBATCH --time=12:00:00
#SBATCH -o {{logPath}}
#SBATCH -J sj{{jobNumber}}
#SBATCH --threads-per-core=1

echo "Start of program at `date`"
Rscript --no-save --no-restore {{jobPath}}
echo "End of program at `date`"'
    controlData <- list(
        threadNum = threadNum,
        jobNumber = jobNumber,
        jobPath = paste0("'",projectPath,"/faustData/slurmScampData/",aLevel,"/slurmScampJob.R","'"),
        logPath = paste0("'",projectPath,"/faustData/slurmScampData/",aLevel,"/sjLog","'")
    )
    renderedScript <- whisker.render(.controlTemplate, controlData)
    write(renderedScript,file=paste0(projectPath,"/faustData/slurmScampData/",aLevel,"/slurmScampJob.sh"))
    return()
}
