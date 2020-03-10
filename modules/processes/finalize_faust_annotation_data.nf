nextflow.preview.dsl=2

process finalizeFAUSTAnnotationData {
    // [ directives ]
    container "rglab/faust-nextflow:cytolib"
    label "standard_mem_and_cpu"
    publishDir "FAUST_RESULTS", mode: "copy", overwrite: false

    input:
        // User
        // N/A
        // Implicit
        file metadata_directory name "./faustData/metaData"
        file samples_data_directory name "./faustData/sampleData"
        file experimental_units_directory name "./faustData/expUnitData/"
        // Execution Specific
        val depth_score_threshold
        val selection_quantile
        val plotting_device
        // Architecture
        val project_path
        val debug_flag


    output:
        path "*faustData/metaData", emit: metadata_directory
        path "*faustData/sampleData", emit: samples_data_directory
        path "*faustData/gateData", emit: gate_data_directory
        path "*faustData/plotData/*", emit: plot_data_directory
        path "*faustData/expUnitData/*", emit: experimental_units_directory

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
        # Plot data needs to be created because it doesn't exist
        plot_data_directory <- file.path(normalizePath("${project_path}"),
                                         "faustData",
                                         "plotData")
        plot_data_histograms_directory <- file.path(plot_data_directory,
                                                    "histograms")
        dir.create(plot_data_directory)
        dir.create(plot_data_histograms_directory)
        # -------------------------
        # Run FAUST
        # -------------------------
        faust:::.selectChannels(depthScoreThreshold=${depth_score_threshold},
                                selectionQuantile=${selection_quantile},
                                projectPath="${project_path}")
        # -----
        faust:::.reconcileAnnotationBoundaries(projectPath="${project_path}",
                                               debugFlag=${debug_flag})
        # -----
        faust:::.superviseReconciliation(projectPath="${project_path}",
                                         debugFlag=${debug_flag})
        # -----
        faust:::.mkAnnMats(projectPath="${project_path}")
        # -----
        faust:::.plotScoreLines(depthScoreThreshold=${depth_score_threshold},
                                selectionQuantile=${selection_quantile},
                                plottingDevice="${plotting_device}",
                                projectPath="${project_path}")
        # -----
        faust:::.plotMarkerHistograms(plottingDevice="${plotting_device}",
                                      projectPath="${project_path}")
        # -----
        faust:::.plotSampleHistograms(plottingDevice="${plotting_device}",
                                      projectPath="${project_path}")

        # ----------------------------------------------------------------------
        code
        """
}
