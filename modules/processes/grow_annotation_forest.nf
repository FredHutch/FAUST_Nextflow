nextflow.preview.dsl=2

params.number_of_iterations = 1

process growAnnotationForest {
    // [ directives ]
    container "rglab/faust-nextflow:cytolib"
    label "large_cpu"

    input:
        // User
        file active_channels_path_channel
        // Implicit
        file metadata_directory name "./faustData/metaData"
        file experimental_unit_directory name "./faustData/expUnitData/"
        // Execution Specific
        val starting_cell_population
        val thread_number
        val seed_value
        // Architecture
        val project_path
        val debug_flag

    output:
        path "*faustData/expUnitData/*", emit: experimental_unit_directory

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

        metadata_directory <- file.path("${project_path}", "faustData", "metaData")
        active_channels_rds_object <- readRDS(file.path(metadata_directory,"activeChannels.rds"))
        sanitized_cell_pop_file_path <- file.path(metadata_directory, "sanitizedCellPopStr.rds")
        sanitized_cell_pop_rds_object <- readRDS(sanitized_cell_pop_file_path)
        analysis_map_file_path <- file.path(metadata_directory, "analysisMap.rds")

        experimental_unit_name <- basename("${experimental_unit_directory}")


        # -------------------------
        # Run FAUST
        # -------------------------
        faust:::.growForestForExpUnit(activeChannels=active_channels_rds_object,
                                      expUnit=experimental_unit_name,
                                      analysisMap=analysis_map_file_path,
                                      rootPop=sanitized_cell_pop_rds_object,
                                      numIter=${params.number_of_iterations},
                                      debugFlag=${debug_flag},
                                      threadNum=${thread_number},
                                      seedValue=${seed_value},
                                      projectPath="${project_path}")

        # ----------------------------------------------------------------------
        code
        """
}