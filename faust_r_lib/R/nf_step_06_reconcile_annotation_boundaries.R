nf_step_06_reconcile_annotation_boundaries <- function(
                                                       supervisedListPath,
                                                       startingCellPop
                                                       )
{
    supervisedList <- readRDS(supervisedListPath)
    analysisMap <- readRDS("analysisMap.rds")
    selectedChannels <- readRDS("initSelC.rds")
    uniqueLevels <- unique(analysisMap[,"analysisLevel",drop=TRUE])
    uniqueIH <- unique(analysisMap[,"impH",drop=TRUE])

    manualList <- forceList <- selectionList <- preferenceList <- list()
    if (is.list(supervisedList)) {
        #supervisedList is a named list of lists
        #name of slot in list: marker
        #list under marker slot 1: string describing type of supervision.
        #list under marker slot 2: vector of ints dictating supervision action.
        supervisedMarkers <- names(supervisedList)
        for (markerNum in seq(length(supervisedMarkers))) {
            marker <- supervisedMarkers[markerNum]
            markerList <- supervisedList[[markerNum]]
            actionType <- markerList[[1]]
            action <- markerList[[2]]
            if (actionType == "Preference")  {
                preferenceList <- append(preferenceList,list(action))
                names(preferenceList)[length(preferenceList)] <- marker
            }
            else if (actionType == "PostSelection")  {
                selectionList <- append(selectionList,list(action))
                names(selectionList)[length(selectionList)] <- marker
            }
            else if (actionType == "Force") {
                forceList <- append(forceList,list(action))
                names(forceList)[length(forceList)] <- marker
            }
            else if (actionType == "Manual") {
                manualList <- append(manualList,list(action))
                names(manualList)[length(manualList)] <- marker
            }
            else {
                print(paste0("Requested unsupported supervision type for marker ", marker))
                print("Only 'Preference' and 'PostSelection' supervision types are currently supported.")
                print(paste0("Ignoring requested action: ",actionType))
            }
        }
    }
    saveRDS(forceList,"forceList.rds")

    gateList <- .nfMakeGateList(
        uniqueLevels=uniqueLevels,
        parentNode=startingCellPop,
        selectedChannels=selectedChannels
    )

    if (length(gateList)) {
        #the gateList is stratifed by the experimental unit.
        saveRDS(gateList,paste0(startingCellPop,"_rawGateList.rds"))
        #hence the number of rows in the numGateMatrix is the number of rows.
        numGateMatrix <- Reduce(rbind,
                                lapply(gateList,
                                       function(x){unlist(lapply(x,
                                                                 function(y){ifelse(is.na(y[1]),0,length(y))}))}))
        if (!is.matrix(numGateMatrix)) numGateMatrix <- t(as.matrix(numGateMatrix))
        rownames(numGateMatrix) <- names(gateList)
        #numSel is a numeric vector.
        #entry is the number of gates selected for the associated marker that annotates the slot.
        numSel <- .nfGetConsistentNumberOfGatesForMarkers(
            numGateMatrix=numGateMatrix,
            preferenceList=preferenceList
        )
        #resList is a container for the gates for all the markers.
        resList <- rep(list(NA),ncol(numGateMatrix))
        names(resList) <- colnames(numGateMatrix)
        for (channel in names(numSel)) {
            #for each marker, get a standard set of annotation boundaries.
            resListUpdate <- rep(list(NA),nrow(numGateMatrix))
            names(resListUpdate) <- rownames(numGateMatrix)
            #gateNumber stores the standard number across the experiment.
            gateNumber <- as.numeric(numSel[channel])
            numLookup <- which(numGateMatrix[,channel]==gateNumber)
            matchLevels <- rownames(numGateMatrix)[numLookup]
            for (currentIH in uniqueIH) {
                #by imputation hierarchy, attempt to standardize gating.
                levelsInIH <- sort(unique(analysisMap[which(analysisMap[,"impH"]==currentIH),"analysisLevel",drop=TRUE]))
                mbLevels <- intersect(matchLevels,levelsInIH)
                if (length(mbLevels)) {
                    #there are levels in the imputation hierarchy that have the gateNumber. use them.
                    gateMatrix <- matrix(nrow=0,ncol=gateNumber)
                    for (level in mbLevels) {
                        gateData <- sort(gateList[[level]][[channel]])
                        gateMatrix <- rbind(gateMatrix,gateData)
                        rownames(gateMatrix)[nrow(gateMatrix)] <- level
                    }
                    cbLookup <- which(rownames(numGateMatrix) %in% levelsInIH)
                    possibleGates <- as.numeric(names(table(numGateMatrix[cbLookup,channel])))
                    possibleGates <- setdiff(possibleGates,c(0,gateNumber))
                    #update the resList
                    for (level in rownames(gateMatrix)) {
                        resListUpdate[[level]] <- sort(gateMatrix[which(rownames(gateMatrix)==level),])
                    }
                    #check for outliers
                    mgMed <- apply(gateMatrix,2,stats::median)
                    mgMAD <- apply(gateMatrix,2,stats::mad)
                    #if we set the gate using only one example (via supervision, or due to sparsity in the
                    #level of the imputation hierarchy), the MAD is 0.
                    #set to (-Inf,Inf) because want to keep what's found by annotation forest. 
                    if (any(mgMAD == 0)) {
                        mgMAD <- Inf
                    }
                    lowVal <- mgMed - (stats::qt(0.975,df=1) * mgMAD)
                    highVal <- mgMed + (stats::qt(0.975,df=1) * mgMAD)
                    chkMatrix <- Reduce(cbind,
                                        lapply(seq(ncol(gateMatrix)),
                                               function(x){(gateMatrix[,x] >= lowVal[x])+(gateMatrix[,x] <= highVal[x])}))
                    #map outliers to medians
                    amendedNames <- c()
                    for (i in seq(ncol(chkMatrix))) {
                        badLookup <- which(chkMatrix[,i] != 2)
                        if (length(badLookup)) {
                            amendedNames <- append(amendedNames,(rownames(gateMatrix)[badLookup]))
                            goodVals <- gateMatrix[-badLookup,i]
                            newVal <- stats::median(goodVals)
                            gateMatrix[badLookup,i] <- newVal
                        }
                    }
                    amendedNames <- sort(unique(amendedNames))
                    if (length(amendedNames)) {
                        for (changeName in amendedNames) {
                            resListUpdate[[changeName]] <- sort(gateMatrix[which(rownames(gateMatrix)==changeName),])
                        }
                    }
                    finalVals <- apply(gateMatrix,2,stats::median)
                    #for levels of analysis with different numbers of gates than the selection,
                    #map them to selected values.
                    if (length(possibleGates)) {
                        for (gateNum in possibleGates) {
                            modLookup <- which(numGateMatrix[,channel]==gateNum)
                            allModSamples <- rownames(numGateMatrix)[modLookup]
                            modSamples <- intersect(allModSamples,levelsInIH)
                            for (modName in modSamples) {
                                modVals <- gateList[[modName]][[channel]]
                                if (gateNum < length(finalVals)) newModVals <- .nfUpConvert(modVals,finalVals)
                                else newModVals <- .nfDownConvert(modVals,finalVals)
                                newModVals <- sort(newModVals)
                                for (mvNum in seq(length(newModVals))) {
                                    if ((newModVals[mvNum] <= lowVal[mvNum]) || (newModVals[mvNum] >= highVal[mvNum])) {
                                        newModVals[mvNum] <- finalVals[mvNum]
                                    }
                                }
                                resListUpdate[[modName]] <- sort(newModVals)
                            }
                        }
                    }
                    #finally deal with NA boundaries in the imputation hierarchy
                    naNames <- intersect(names(which(is.na(resListUpdate))),levelsInIH)
                    if (length(naNames)) {
                        for (changeName in naNames) {
                            resListUpdate[[changeName]] <- sort(finalVals)
                        }
                    }
                }
            }
            if (length(which(is.na(resListUpdate)))) {
                #experimental units within a level of the imputation hierarchy do not have annotation boundaries.
                #so, impute boundaries across all levels in the imputation hierarchy.
                gateMatrix <- matrix(nrow=0,ncol=gateNumber)
                for (level in names(which(!is.na(resListUpdate)))) {
                    gateData <- sort(resListUpdate[[level]])
                    gateMatrix <- rbind(gateMatrix,gateData)
                    rownames(gateMatrix)[nrow(gateMatrix)] <- level
                }
                finalVals <- apply(gateMatrix,2,stats::median)
                #map those still NA to the experiment wide medians.
                naNames <- names(which(is.na(resListUpdate)))
                for (changeName in naNames) {
                    resListUpdate[[changeName]] <- sort(finalVals)
                }
            }
            resList[[channel]] <- resListUpdate
        }
        if (length(forceList) > 0) {
            #the user has indicated a channel must be included in the anlaysis and gated at a value.
            #add it in now, overwriting any automatic reconciliation.
            forcedNames <- names(forceList)
            listTemplate <- resList[[1]]
            designSettings <- names(listTemplate)
            selectedChannelsPrep <- selectedChannels
            for (forcedMarkerName in forcedNames) {
                forcedGates <- forceList[[forcedMarkerName]] #the forced gate values
                newTemplate <- listTemplate #copy the template for updating
                for (setting in designSettings) {
                    newTemplate[[setting]] <- forcedGates
                }
                if (forcedMarkerName %in% selectedChannelsPrep) {
                    print(paste0("Overwriting empirical gates for user settings on marker ",
                                 forcedMarkerName))
                    resList[[forcedMarkerName]] <- newTemplate
                }
                else {
                    resList <- append(resList,list(newTemplate))
                    names(resList)[length(resList)] <- forcedMarkerName
                    selectedChannelsPrep <- append(selectedChannelsPrep,
                                                  forcedMarkerName)
                }
            }
        }
        else {
            selectedChannelsPrep <- selectedChannels
        }
        if (length(manualList) > 0) {
            #the user has provided manual gates for some marker.
            #add these gates in now.
            #one of two conditions must be met.
            #either the marker must be selected automatically by FAUST.
            #or manual gates must be provided for ALL levels by the user.
            #if the case the marker is selected by FAUST, a subsets of levels may be manually gated.
            manualNames <- names(manualList)
            listTemplate <- resList[[1]]
            designSettings <- names(listTemplate)
            selectedChannelsOut <- selectedChannelsPrep
            for (manualMarkerName in manualNames) {
                manualGateList <- manualList[[manualMarkerName]] #the forced gate values
                manualSettings <- names(manualGateList)
                if (manualMarkerName %in% selectedChannelsOut) {
                    #the marker is selected and gated by FAUST. 
                    #get faust gates and update only those levels modified by the user.
                    newTemplate <- resList[[manualMarkerName]]
                    for (setting in manualSettings) {
                        newTemplate[[setting]] <- manualGateList[[setting]]
                    }
                    resList[[manualMarkerName]] <- newTemplate
                }
                else {
                    #the marker is not selected by FAUST
                    #therefore, the user must set gates for all design levels.
                    #check to make sure this occurs before updating.
                    newTemplate <- listTemplate
                    if (length(setdiff(designSettings,manualSettings))) {
                        print("Manual gates do not include all levels.")
                        print("Set gates for the following.")
                        print(setdiff(designSettings,manualSettings))
                        stop("Killing faust run.")
                    }
                    if (length(setdiff(manualSettings,designSettings))) {
                        print("Manual gates include levels not specified by the design.")
                        print("These levels are the following.")
                        print(setdiff(manualSettings,designSettings))
                        stop("Killing faust run.")
                    }
                    for (setting in manualSettings) {
                        newTemplate[[setting]] <- manualGateList[[setting]]
                    }
                    resList <- append(resList,list(newTemplate))
                    names(resList)[length(resList)] <- manualMarkerName
                    selectedChannelsOut <- append(selectedChannelsOut,
                                                  manualMarkerName)
                }
            }
        }
        else {
            selectedChannelsOut <- selectedChannelsPrep
        }
        saveRDS(resList,paste0(startingCellPop,"_resListPrep.rds"))
        saveRDS(selectedChannelsOut,paste0(startingCellPop,"_selectedChannels.rds"))
    }
    outList <- readRDS(paste0(startingCellPop,"_resListPrep.rds"))
    if (length(selectionList) > 0) {
        #selectedChannels <- names(resListPrep)
        selectedChannels <- names(outList)
        supervisedChannels <- names(selectionList)
        if (length(setdiff(supervisedChannels,selectedChannels))) {
            print("The following unselected channels (by depth score) are detected.")
            print(setdiff(supervisedChannels,selectedChannels))
            print("Proceding as if these are controlled values.")
        }
        for (channel in supervisedChannels) {
            tmpList <- outList[[channel]]
            supervision <- selectionList[[channel]]
            if (length(supervision) > length(tmpList[[1]])) {
                stop("Attempting to set more gates than exist post-reconciliation.")
            }
            if (max(supervision) > length(tmpList[[1]])) {
                stop("Attempting to set a gate beyond the last gate existing post-reconciliation.")
            }
            if (min(supervision) < 1) {
                stop("Attempting to set a gate beneath the first gate existing post-reconciliation.")
            }
            for (gateNum in seq(length(tmpList))) {
                tmpList[[gateNum]] <- tmpList[[gateNum]][supervision]
            }
            outList[[channel]] <- tmpList
        }
    }
    saveRDS(outList,paste0(startingCellPop,"_resList.rds"))
    return()
}

.nfMakeGateList <- function(uniqueLevels,parentNode,selectedChannels)
{
    gateList <- list()
    for (aLevel in uniqueLevels) {
        if (file.exists(paste0(aLevel,"_",parentNode,"_pAnnF.rds"))) {
            afIn <- readRDS(paste0(aLevel,"_",parentNode,"_pAnnF.rds"))
            gates <- lapply(selectedChannels,
                            function(x){eval(parse(text=paste0("afIn$`",x,"`$gates")))})
            if (length(gates) == length(selectedChannels)) {
                names(gates) <- selectedChannels
                gateList <- append(gateList,list(gates))
                names(gateList)[length(gateList)] <- aLevel
            }
        }
        else {
            print(paste0(aLevel,": no parsed forest detected."))
        }
    }
    return(gateList)
}

.nfGetConsistentNumberOfGatesForMarkers <- function(numGateMatrix,preferenceList)
{
    numSel <- c()
    possibilityList <- list()
    if (length(preferenceList) > 0) preferredMarkers <- names(preferenceList)
    for (columnName in colnames(numGateMatrix)) {
        nzLookup <- which(numGateMatrix[,columnName] > 0)
        if (length(nzLookup)==0) {
            print(numGateMatrix)
            print(columnName)
            stop("Invalid reconciliation")
        }
        columnSub <- numGateMatrix[nzLookup,columnName]
        columnCounts <- table(columnSub)
        possibilityList <- append(possibilityList,list(columnCounts))
        names(possibilityList)[length(possibilityList)] <- columnName
        columnMax <- max(columnCounts)
        if ((length(preferenceList) > 0) && (columnName %in% preferredMarkers)) {
            #user has requested a particular number of gates for this marker. 
            #if there is empirical evidence for this choice, accommodate it. 
            #otherwise, defer to max choice.
            columnPreference <- preferenceList[[columnName]]
            preferenceLookup <- which(as.numeric(names(columnCounts)) == as.numeric(columnPreference))
            if (length(preferenceLookup) > 0) {
                #we have observed the preference in the data.
                selUpdate <- as.numeric(columnPreference)
            }
            else {
                #the request is not supported by the data. Use standard rule.
                selUpdate <- sort(as.numeric(names(which(columnCounts==columnMax))))[1]
            }
        }
        else {
            selUpdate <- sort(as.numeric(names(which(columnCounts==columnMax))))[1] #if non-zero ties, pick min
        }
        numSel <- append(numSel,selUpdate)
        names(numSel)[length(numSel)] <- columnName
    }
    #save the possible number of gates for all selected markers in the experiment.
    #users can examine this data to override max selection
    saveRDS(possibilityList,paste0("possibilityList.rds"))
    return(numSel)
}



.nfUpConvert <- function(fromGates,toGates) {
    #toGates is assumed sorted in increasing order.
    dropInds <- c()
    outGates <- c()
    for (gate in fromGates) {
        #for each fromGate, find closest to gate and record index
        diffVec <- abs(toGates-gate)
        minDiff <- which(diffVec==min(diffVec))
        dropInds <- append(dropInds,minDiff[1]) #always keep higher gates.
        outGates <- append(outGates,gate)
    }
    #if multiple fromGates match a single toGate, use smallest fromGate
    uniqDrops <- sort(unique(dropInds))
    if (length(uniqDrops) != length(dropInds)) {
        finalOG <- c()
        for (indexVal in uniqDrops) {
            finalOG <- append(finalOG,outGates[which(dropInds == indexVal)][1])
        }
    }
    else {
        finalOG <- outGates
    }
    #copy over indices which are not explained 
    #note length(uniqDrops)>0 since length(toGates) > length(fromGates)
    finalOG <- sort(unique(append(finalOG,toGates[-uniqDrops])))
    if (length(finalOG) != length(toGates)) {
        stop("Upconversion error.")
    }
    return(finalOG)
}
#.nfUpConvert(c(5),c(2.5,8)) == c(5,8)
#.nfUpConvert(c(5),c(2.5,7.5,10)) == c(5,7.5,10)
#.nfUpConvert(c(5,6),c(2.5,10,15)) == c(5,10,15)
#.nfUpConvert(c(5,6),c(2.5,8,15)) == c(5,6,15)

.nfDownConvert <- function(fromGates,toGates) {
    #toGates is assumed sorted in increasing order.
    minInds <- c()
    minDiffVals <- c()
    for (gate in fromGates) {
        diffVec <- abs(toGates-gate)
        minVal <- min(diffVec)
        minDiff <- which(diffVec==minVal)
        minInds <- append(minInds,minDiff[1])#always match to lower gate in ties
        minDiffVals <- append(minDiffVals,minVal)
    }
    uniqMinInds <- sort(unique(minInds))
     #take the best of the fromGates that map to toGates
    finalOG <- c()
    for (indexVal in uniqMinInds) {
        subLookup <- which(minInds==indexVal)
        subDiffVals <- minDiffVals[subLookup]
        subGates <- fromGates[subLookup]
        allKeepInd <- which(subDiffVals == min(subDiffVals))
        keepInd <- allKeepInd[length(allKeepInd)]
        finalOG <- append(finalOG,subGates[keepInd])
    }
    #add on the toGates unaccounted for
    if (length(uniqMinInds) != length(toGates)) {
        remInds <- setdiff(seq(length(toGates)),uniqMinInds)
        finalOG <- append(finalOG,toGates[remInds])
    }
    finalOG <- sort(unique(finalOG))
    if (length(finalOG) != length(toGates)) {
        stop("Downconversion error.")
    }
    return(finalOG)
}
#.nfDownConvert(c(1,2,3,4),c(5,10)) == c(4,10)
#.nfDownConvert(c(1,2,3,4),c(0,5,10)) == c(1,4,10)
#.nfDownConvert(c(-1,1,2,3,4),c(0,5,10)) == c(1,4,10)
