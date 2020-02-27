nextflow.preview.dsl=2

process plotPhenotypeFilter {
    // [ directives ]
    container "rglab/faust-nextflow:1.0.0"
    label "standard_mem_and_cpu"
    publishDir "FAUST_RESULTS", mode: "copy", overwrite: false

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
        path "*faustData/plotData/*", emit: output_files

    script:
        """
        R --no-save <<code
        # ----------------------------------------------------------------------
        # -------------------------
        # Environment
        # -------------------------
        library("faust")

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
        clusterNames <- names(nameSummary[which(nameSummary >= ${name_occurrence_number})])
        saveRDS(clusterNames,
                file.path(normalizePath("${project_path}"),
                          "faustData",
                          "metaData",
                          "scampClusterNames.rds"))
        # ---
        faust:::.plotPhenotypeFilter(nameOccuranceNum=${name_occurrence_number},
                                     plottingDevice="${plotting_device}",
                                     projectPath="${project_path}")
        # ----------------------------------------------------------------------
        code
        """
}