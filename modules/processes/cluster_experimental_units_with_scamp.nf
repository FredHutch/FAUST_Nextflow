nextflow.preview.dsl=2

process clusterExperimentalUnitsWithScamp {
    // [ directives ]
    container "rglab/faust-nextflow:cytolib"
    label "large_cpu"
    // echo true

    input:
        // User
        // N/A
        // Implicit
        file metadata_directory name "./faustData/metaData"
        file samples_data_directory name "./faustData/sampleData"
        file experimental_unit_directory name "./faustData/expUnitData/"
        file gate_data_directory name "./faustData/gateData"
        // Execution Specific
        val starting_cell_population
        val name_occurrence_number
        val plotting_device
        // Architecture
        val project_path
        val debug_flag
        val thread_number
        val seed_value

    output:
        path "*faustData/metaData", emit: metadata_directory
        path "*faustData/sampleData/*", emit: samples_data_directory
        path "*faustData/expUnitData/*", emit: experimental_units_directory

    script:
        """
        R --no-save <<code
        # ----------------------------------------------------------------------
        # -------------------------
        # Environment
        # -------------------------
        library("faust")

        list.dirs("./faustData/expUnitData")
        list.files("./faustData/expUnitData/s1")
        list.files("./faustData/expUnitData/s2")

        # -------------------------
        # FAUST Data
        # -------------------------
        number_of_scamp_iterations <- 1

        experimental_unit_name <- basename("${experimental_unit_directory}")
        # experimental_unit_expressions_file_path <- file.path("${experimental_unit_directory}", "expUnitExprs.rds")
        # experimental_unit_restrictions_file_path <- file.path("${experimental_unit_directory}", "expUnitRes.rds")
        restriction_list_file_path <- file.path(normalizePath("${project_path}"),
                                                "faustData",
                                                "gateData",
                                                paste0("${starting_cell_population}", "_resList.rds"))
        restriction_list_rds_object <- readRDS(restriction_list_file_path)
        selected_channels_file_path <- file.path(normalizePath("${project_path}"),
                                                 "faustData",
                                                 "gateData",
                                                 paste0("${starting_cell_population}", "_selectedChannels.rds"))
        selected_channels_rds_object <- readRDS(selected_channels_file_path)

        # -------------------------
        # Run FAUST
        # -------------------------
        faust:::.clusterExpUnitWithScamp(expUnit=experimental_unit_name,
                                         resList=restriction_list_rds_object,
                                         selectedChannels=selected_channels_rds_object,
                                         numScampIter=number_of_scamp_iterations,
                                         threadNum=${thread_number},
                                         seedValue=${seed_value},
                                         projectPath="${project_path}",
                                         debugFlag=${debug_flag})

        # clusterExperimentalUnitsWithScampTesting
        list.files("./faustData/sampleData/s1")
        list.files("./faustData/sampleData/s2")

        # -------------------------
        # Post FAUST
        # -------------------------
        # Needs to remove all un-needed sample directories in order to only
        # return the correct sample files with the correct mutated data
        experimental_unit_to_sample_lookup_file_path <- file.path(normalizePath("${project_path}"),
                                                                                "faustData",
                                                                                "expUnitData",
                                                                                experimental_unit_name,
                                                                                "expUnitToSampleLookup.rds")
        print(experimental_unit_to_sample_lookup_file_path)
        all_experimental_unit_samples <- names(table(readRDS(experimental_unit_to_sample_lookup_file_path)))
        print(all_experimental_unit_samples)
        sample_data_directory_path <- file.path(normalizePath("${project_path}"),
                                                              "faustData",
                                                              "sampleData")
        print(sample_data_directory_path)
        all_sample_directories <- list.dirs(sample_data_directory_path, recursive=FALSE)
        all_sample_directory_names <- basename(all_sample_directories)
        print(all_sample_directory_names)
        directory_names_to_delete <- setdiff(all_sample_directory_names, all_experimental_unit_samples)
        print(directory_names_to_delete)
        directory_paths_to_delete <- file.path(normalizePath("${project_path}"),
                                               "faustData",
                                               "sampleData",
                                               directory_names_to_delete)
        print(directory_paths_to_delete)
        unlink(directory_paths_to_delete, recursive=TRUE)
        list.dirs(sample_data_directory_path)

        # ----------------------------------------------------------------------
        code
        """
}