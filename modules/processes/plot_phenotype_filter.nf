nextflow.preview.dsl=2

process plotPhenotypeFilter {
    // [ directives ]
    container "rglab/faust-nextflow:0.5.0"
    label "standard_mem_and_cpu"
    publishDir "FAUST_RESULTS", mode: "copy", overwrite: true

    input:
        // User
        // N/A
        // Implicit
        file metadata_directory name "./faustData/metaData"
        file experimental_unit_directory name "./faustData/expUnitData/"
        // Execution Specific
        val name_occurrence_number
        val plotting_device
        // Architecture
        val project_path
        val debug_flag

    output:
        path "*faustData/metaData", emit: metadata_directory
        path "*faustData/plotData/*", emit: plot_data_directory
        path "*faustData/expUnitData/*", emit: experimental_unit_directory

    script:
        """
        R --no-save <<code
        # ----------------------------------------------------------------------
        # -------------------------
        # Environment
        # -------------------------
        library("faust")
        library("fdrtool")

        # -------------------------
        # FAUST Data
        # -------------------------
        # Need to get all the experimental unit names
        experimental_unit_data_directory_path <- file.path("${project_path}", "faustData", "expUnitData")
        unique_experimental_unit_directory_paths <- list.dirs(experimental_unit_data_directory_path, recursive=FALSE)
        unique_experimental_unit_names <- basename(unique_experimental_unit_directory_paths)

        # Plot data needs to be created because it doesn't exist
        plot_data_directory <- file.path(normalizePath("${project_path}"),
                                         "faustData",
                                         "plotData")
        dir.create(plot_data_directory)

        # -------------------------
        # Run FAUST
        # -------------------------
        # # ---
        # generate scamp files
        # ---
        clusterNames <- c()
        for (experimentalUnit in unique_experimental_unit_names) {
            expUnitLabels <- readRDS(file.path(normalizePath("${project_path}"),
                                             "faustData",
                                             "expUnitData",
                                             experimentalUnit,
                                             "scampClusterLabels.rds"))
            clusterNames <- append(clusterNames,expUnitLabels)
        }
        nameSummary <- table(clusterNames)
        saveRDS(nameSummary,
                file.path(normalizePath("${project_path}"),
                          "faustData",
                          "metaData",
                          "scampNameSummary.rds"))

        # ======================================================================
        nameSummaryPlotDF <- data.frame(x=seq(max(nameSummary)),
                                y=sapply(seq(max(nameSummary)),function(x){
                                    length(which(nameSummary >= x))}))

        .computeElbow <- function(phenoDF) {
            if (nrow(phenoDF) < 4) {
                #if a dataset has 3 or fewer samples, default to using all
                #phenotypes from the scamp clusterings.
                elbowLocation <- 1
            }
            else {
                #dynamically estimate the elbow by projecting knots of the GCM
                #of the distribution of phenotypes onto the line of
                #observed phenotypes at 5th and 95th rows of the phenoDF
                #trim the extremes to moderate the slopes.
                lowerIndex <- max(2,ceiling(0.05*nrow(phenoDF)))
                upperIndex <- min((nrow(phenoDF)-1),floor(0.95*nrow(phenoDF)))
                elbowDF <- phenoDF[seq(lowerIndex,upperIndex),,drop=FALSE]
                elbX2 <- elbowDF[nrow(elbowDF),"x"]
                elbX1 <- elbowDF[1,"x"]
                elbY2 <- elbowDF[nrow(elbowDF),"y"]
                elbY1 <- elbowDF[1,"y"]
                elbM <- (elbY2-elbY1)/(elbX2-elbX1)
                elbC <- elbY1-(elbM * elbX1)
                lineMin <- function(pt){
                    return(abs(pt[2] - elbM*pt[1] - elbC)/sqrt(1+(elbM^2)))
                }
                gcmEst <- fdrtool::gcmlcm(
                                       x=elbowDF[,"x", drop=TRUE],
                                       y=elbowDF[,"y", drop=TRUE],
                                       type="gcm"
                                   )
                candElbow <- apply(cbind(gcmEst[["x.knots"]],gcmEst[["y.knots"]]),1,lineMin)
                elbowLocation <- gcmEst[["x.knots"]][which(candElbow==max(candElbow))[1]]
            }
            return(elbowLocation)
        }
        elbowLoc <- .computeElbow(nameSummaryPlotDF)

        #use the automatic value.
        clusterNames <- names(nameSummary[which(nameSummary >= elbowLoc)])
        saveRDS(
            elbowLoc,
            file.path(normalizePath("${project_path}"),
                      "faustData",
                      "metaData",
                      "phenotypeElbowValue.rds")
        )

        if (${name_occurrence_number} > 0) {
            #the user has set this value
            clusterNames <- names(nameSummary[which(nameSummary >= ${name_occurrence_number})])
            saveRDS(
                ${name_occurrence_number},
                file.path(normalizePath("${project_path}"),
                          "faustData",
                          "metaData",
                          "phenotypeElbowValue.rds")
            )
        }
        saveRDS(clusterNames,
                file.path(normalizePath("${project_path}"),
                          "faustData",
                          "metaData",
                          "scampClusterNames.rds"))

        allClusterNames <- names(nameSummary[which(nameSummary >= 1)])
        saveRDS(allClusterNames,
               file.path(normalizePath("${project_path}"),
                         "faustData",
                         "metaData",
                          "allScampClusterNames.rds"))
        # ======================================================================
        # ---
        faust:::.plotPhenotypeFilter(nameOccuranceNum=${name_occurrence_number},
                                     plottingDevice="${plotting_device}",
                                     projectPath="${project_path}")
        # ----------------------------------------------------------------------
        code
        """
}
