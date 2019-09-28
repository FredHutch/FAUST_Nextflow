.growForestForALevel <- function(aLevel,
                                 rootPop,
                                 activeChannels,
                                 analysisMap,
                                 numIter,
                                 debugFlag,
                                 threadNum,
                                 seedValue,
                                 projectPath,
                                 densitySubSampleThreshold,
                                 densitySubSampleSize,
                                 densitySubSampleIterations)
{
    #function to 
    if (debugFlag) print(paste0("Growing annotation forest for: ",aLevel))
    levelExprs <- readRDS(paste0(projectPath,"/faustData/levelData/",aLevel,"/levelExprs.rds"))
    levelRes <- readRDS(paste0(projectPath,"/faustData/levelData/",aLevel,"/levelRes.rds"))
    levelExprs <- levelExprs[,activeChannels,drop=FALSE]
    levelRes <- levelRes[,activeChannels,drop=FALSE]
    resFlag <- FALSE
    for (colNum in seq(ncol(levelRes))) {
        if (length(which(levelRes[,colNum] > 0))) {
            resFlag <- TRUE
            break
        }
    }
    annF <- growAnnotationForest(
        dataSet=levelExprs,
        numberIterations=numIter,
        pValueThreshold=0.25,
        minimumClusterSize=25,
        randomCandidateSearch=FALSE,
        maximumSearchDepth=2,
        numberOfThreads=threadNum,
        maximumGatingNum=1e10,
        anyValueRestricted=resFlag,
        resValMatrix=levelRes,
        cutPointUpperBound=2,
        getDebugInfo=FALSE,
        randomSeed=seedValue,
        subSamplingThreshold=densitySubSampleThreshold,
        subSampleSize=densitySubSampleSize,
        subSampleIter=densitySubSampleIterations,
        recordCounts=FALSE,
        recordIndices=FALSE
    )
    saveRDS(annF,paste0(projectPath,"/faustData/levelData/",aLevel,"/",rootPop,"_annF.rds"))
    ePop <- apply(levelRes,2,function(x){length(which(x==0))})
    names(ePop) <- colnames(levelExprs)
    af <- annF[["gateData"]]
    pAnnF <- .parseAnnotationForest(af,ePop)
    saveRDS(pAnnF,paste0(projectPath,"/faustData/levelData/",aLevel,"/",rootPop,"_pAnnF.rds"))
    aLevelDone <- TRUE
    saveRDS(aLevelDone,paste0(projectPath,"/faustData/levelData/",aLevel,"/aLevelComplete.rds"))
    if (debugFlag) print(paste0("Annotation forest complete for: ",aLevel))
    return()
}



.growAnnForest <- function(rootPop,
                           activeChannels,
                           analysisMap,
                           numIter,
                           debugFlag,
                           threadNum,
                           seedValue,
                           projectPath,
                           densitySubSampleThreshold,
                           densitySubSampleSize,
                           densitySubSampleIterations,
                           archDescriptionList)

{
    uniqueLevels <- sort(unique(analysisMap[,"analysisLevel"]))
    activeLevels <- c()
    #accumulate vector of levels without annotation forests.
    for (analysisLevel in uniqueLevels) {
        if (!file.exists(paste0(projectPath,"/faustData/levelData/",analysisLevel,"/aLevelComplete.rds"))) {
            activeLevels <- append(activeLevels,analysisLevel)
        }
    }
    #grow forests for levels that lack them
    if ((length(activeLevels)) && (archDescriptionList$targetArch=="singleCPU")) {
        while (length(activeLevels)) {
            currentLevel <- activeLevels[1]
            activeLevels <- activeLevels[-1]
            .growForestForALevel(
                aLevel=currentLevel,
                rootPop=rootPop,
                activeChannels=activeChannels,
                analysisMap=analysisMap,
                numIter=numIter,
                debugFlag=debugFlag,
                threadNum=threadNum,
                seedValue=seedValue,
                projectPath=projectPath,
                densitySubSampleThreshold=densitySubSampleThreshold,
                densitySubSampleSize=densitySubSampleSize,
                densitySubSampleIterations=densitySubSampleIterations
            )
        }
    }
    else if ((length(activeLevels)) && (archDescriptionList$targetArch=="slurmCluster")) {
        if (!dir.exists(paste0(projectPath,"/faustData/slurmData"))) {
            dir.create(paste0(projectPath,"/faustData/slurmData"))
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
                if (!dir.exists(paste0(projectPath,"/faustData/slurmData/",currentLevel))) {
                    dir.create(paste0(projectPath,"/faustData/slurmData/",currentLevel))
                }
                .prepareSlurmJob(
                    aLevel=currentLevel,
                    rootPop=rootPop,
                    activeChannels=activeChannels,
                    analysisMap=analysisMap,
                    numIter=numIter,
                    threadNum=archDescriptionList$nodeThreadNum,
                    seedValue=seedValue,
                    projectPath=projectPath,
                    densitySubSampleThreshold=densitySubSampleThreshold,
                    densitySubSampleSize=densitySubSampleSize,
                    densitySubSampleIterations=densitySubSampleIterations,
                    jobNumber = jobNum
                )
                print(paste0("Slurm annotation forest starting for ", currentLevel))
                launchJob <- system2("sbatch",
                                     args=paste0(sbatchFlags,
                                                 paste0(" '",projectPath,
                                                        "/faustData/slurmData/",
                                                        currentLevel,
                                                        "/slurmJob.sh","'")
                                                 ),
                                     stdout=TRUE)
            }
            else {
                Sys.sleep(10) #in seconds
                currentSlurmTime <- (proc.time() - startSlurmTime)
                if (as.numeric(currentSlurmTime[3]) > maxTime) {
                    print("Slurm annotation forest exceeded max time.")
                    print("Check logs in /faustData/slurmData")
                    stop("Killing FAUST")
                }
                activeSlurmLevels <- c()
                for (sLevel in slurmLevels) {
                    if ((file.exists(paste0(projectPath,
                                            "/faustData/slurmData/",
                                            sLevel,
                                            "/slurmComplete.rds"))) &&
                        (readRDS(paste0(projectPath,
                                        "/faustData/slurmData/",
                                        sLevel,
                                        "/slurmComplete.rds"))))
                    {
                        print(paste0("Slurm annotation forest complete for ", sLevel))
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
    return()
}

.prepareSlurmJob <- function(aLevel,
                             rootPop,
                             activeChannels,
                             analysisMap,
                             numIter,
                             threadNum,
                             seedValue,
                             projectPath,
                             densitySubSampleThreshold,
                             densitySubSampleSize,
                             densitySubSampleIterations,
                             jobNumber)
{
    .programTemplate <-'library(faust)
levelExprs <- readRDS(paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/levelExprs.rds"))
levelRes <- readRDS(paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/levelRes.rds"))
levelExprs <- levelExprs[,{{activeChannels}},drop=FALSE]
levelRes <- levelRes[,{{activeChannels}},drop=FALSE]
resFlag <- FALSE
for (colNum in seq(ncol(levelRes))) {
if (length(which(levelRes[,colNum] > 0))) {
resFlag <- TRUE
break
}
}
annF <- faust:::growAnnotationForest(
dataSet=levelExprs,
numberIterations={{numIter}},
pValueThreshold=0.25,
minimumClusterSize=25,
randomCandidateSearch=FALSE,
maximumSearchDepth=2,
numberOfThreads={{threadNum}},
maximumGatingNum=1e10,
anyValueRestricted=resFlag,
resValMatrix=levelRes,
cutPointUpperBound=2,
getDebugInfo=FALSE,
randomSeed={{seedValue}},
subSamplingThreshold={{densitySubSampleThreshold}},
subSampleSize={{densitySubSampleSize}},
subSampleIter={{densitySubSampleIterations}},
recordCounts=FALSE,
recordIndices=FALSE
)
saveRDS(annF,paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/",{{rootPop}},"_annF.rds"))
ePop <- apply(levelRes,2,function(x){length(which(x==0))})
names(ePop) <- colnames(levelExprs)
af <- annF[["gateData"]]
pAnnF <- faust:::.parseAnnotationForest(af,ePop)
saveRDS(pAnnF,paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/",{{rootPop}},"_pAnnF.rds"))
aLevelDone <- TRUE
saveRDS(aLevelDone,paste0({{projectPath}},"/faustData/levelData/",{{aLevel}},"/aLevelComplete.rds"))
slurmDone <- TRUE
saveRDS(slurmDone,paste0({{projectPath}},"/faustData/slurmData/",{{aLevel}},"/slurmComplete.rds"))
'
    programData <- list(
        aLevel=paste0("'",aLevel,"'"),
        rootPop=paste0("'",rootPop,"'"),
        activeChannels=paste0("c('",paste0(activeChannels,collapse="','"),"')"),
        numIter=numIter,
        threadNum=threadNum,
        seedValue=seedValue,
        projectPath=paste0("'",projectPath,"'"),
        densitySubSampleThreshold=densitySubSampleThreshold,
        densitySubSampleSize=densitySubSampleSize,
        densitySubSampleIterations=densitySubSampleIterations
    )
    renderedProgram <- whisker.render(.programTemplate, programData)
    write(renderedProgram,file=paste0(projectPath,"/faustData/slurmData/",aLevel,"/slurmJob.R"))
    .controlTemplate <-'#!/bin/bash
#SBATCH --partition=largenode
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task={{threadNum}}
#SBATCH --time=12:00:00
#SBATCH -o {{logPath}}
#SBATCH -J fj{{jobNumber}}
#SBATCH --threads-per-core=1

echo "Start of program at `date`"
Rscript --no-save --no-restore {{jobPath}}
echo "End of program at `date`"'
    controlData <- list(
        threadNum = threadNum,
        jobNumber = jobNumber,
        jobPath = paste0("'",projectPath,"/faustData/slurmData/",aLevel,"/slurmJob.R","'"),
        logPath = paste0("'",projectPath,"/faustData/slurmData/",aLevel,"/fjLog","'")
    )
    renderedScript <- whisker.render(.controlTemplate, controlData)
    write(renderedScript,file=paste0(projectPath,"/faustData/slurmData/",aLevel,"/slurmJob.sh"))
    return()
}
