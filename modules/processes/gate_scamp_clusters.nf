nextflow.preview.dsl=2

process gateScampClusters {
    // [ directives ]
    container "rglab/faust-nextflow:cytolib"
    label "standard_mem_and_cpu"
    publishDir "FAUST_RESULTS", mode: "copy", overwrite: true 
    echo true

    input:
        // User
        // N/A
        // Implicit
        file metadata_directory name "./faustData/metaData"
        file samples_data_directory name "./faustData/sampleData/"
        file gate_data_directory name "./faustData/gateData"
        // Execution Specific
        // N/A
        // Architecture
        val project_path
        val debug_flag

    output:
        path "./faustData/metaData/colNameMap.rds", emit: faust_column_name_map
        path "./faustData/faustCountMatrix.rds", emit: faust_count_matrix

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
        # N/A
        # gateScampClustersTesting
        list.dirs()
        list.files()
        list.dirs("./faustData/sampleData")
        list.files("./faustData/sampleData/s1")
        list.files("./faustData/sampleData/s2")


        # -------------------------
        # Run FAUST
        # -------------------------
        faust:::.gateScampClusters(projectPath="${project_path}",
                                   debugFlag=${debug_flag})
        faust:::.getFaustCountMatrix(projectPath="${project_path}",
                                     debugFlag=${debug_flag})
        # ----------------------------------------------------------------------
        code
        """
}
