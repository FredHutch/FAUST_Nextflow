#!/usr/bin/env nextflow


// NextFlow Input
params.input_gating_set_directory = "$baseDir/input"
params.active_channels_path = "$baseDir/helper_files/active_channels.rds"
params.channel_bounds_path = "$baseDir/helper_files/channel_bounds.rds"
params.supervised_list_path = "$baseDir/helper_files/supervised_list.rds"

// FAUST Specific Tuninig
params.annotations_approved = "TRUE"
params.depth_score_threshold = 0.05
params.experimental_unit = "name"
params.imputation_hierarchy= "flatHierarchy"
params.name_occurrence_number=1
params.starting_cell_pop = "root"
params.selection_quantile = 1
params.thread_number = 0

// -----------------------------------------------------------------------------
// step 00
// -----------------------------------------------------------------------------
process initialize_faust_data {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "high_memory"

    input:
        file input_directory from file(params.input_gating_set_directory, type: "dir")

    output:
        set file(input_directory), file('analysisMap.rds') into STEP_01_CHANNEL

    script:
        """
        #!/usr/bin/env Rscript
        library(faust)
        faust:::nf_step_00_initialize_faust_data(gatingSetPath="${input_directory}",
                                                 experimentalUnit="${params.experimental_unit}",
                                                 imputationHierarchy="${params.imputation_hierarchy}")
        """
}

// -----------------------------------------------------------------------------
// step 01
// -----------------------------------------------------------------------------
process extract_data {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "high_memory"

    input:
        set file(input_directory), file(analysis_map) from STEP_01_CHANNEL
        file active_channels from file("${params.active_channels_path}")

    output:
        file('*_exprsMat.rds') into STEP_02_CHANNEL
       set file(input_directory), file(analysis_map) into STEP_02_GS

    script:
        """
        #!/usr/bin/env Rscript

        library(faust)
        faust:::nf_step_01_extract_data_from_gs(gatingSetPath="${input_directory}",
                                                activeChannelsPath="${active_channels}",
                                                startingCellPop="${params.starting_cell_pop}")
        """
}

// -----------------------------------------------------------------------------
// step 02
// -----------------------------------------------------------------------------
process make_restriction_matrices {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "high_memory"

    input:
        set file(input_directory), file(analysis_map) from  STEP_02_GS
        file(sample_expression_mats) from STEP_02_CHANNEL.collect()
        file channel_bounds from file("${params.channel_bounds_path}")

    output:
        set file(input_directory), file(analysis_map),file('channelBoundsUsedByFAUST.rds'), file('*_resMat.rds') into STEP_03_CHANNEL
        file(sample_expression_mats) into STEP_03_SAMPLE_CHANNEL

    script:
        """
        #!/usr/bin/env Rscript

        library(faust)
        faust:::nf_step_02_make_restriction_matrices(gatingSetPath="${input_directory}",
                                                     channelBoundsPath="${channel_bounds}")
        """
}

// -----------------------------------------------------------------------------
// step 03
// -----------------------------------------------------------------------------
process make_experimental_units {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"

    input:
        set file(input_directory), file(analysis_map),file(channel_bounds_used_by_faust),file(restriction_matrix) from STEP_03_CHANNEL
        file sample from STEP_03_SAMPLE_CHANNEL.collect()

    output: 
        file(analysis_map) into STEP_04_ANALYSIS_MAP_CHANNEL
        file('*_levelExprs.rds') into STEP_04_LEVEL_EXPRS_CHANNEL
        file('*_levelLookup.rds') into STEP_04_LEVEL_LOOKUP_CHANNEL
        file('*_levelRes.rds') into STEP_04_LEVEL_RES_CHANNEL
        file sample into STEP_07_SAMPLE_CHANNEL

    script:
        """
        #!/usr/bin/env Rscript

        library(faust)
        faust:::nf_step_03_make_experimental_units()
        """
}

// -----------------------------------------------------------------------------
// step 04
// -----------------------------------------------------------------------------
STEP_04_LEVEL_EXPRS_KEY_CHANNEL = STEP_04_LEVEL_EXPRS_CHANNEL.flatten().map { 
    file -> 
        def key = file.name.toString().replaceAll(/_levelExprs\.rds/,"")
        return tuple(key,file)
}
STEP_04_LEVEL_LOOKUP_KEY_CHANNEL = STEP_04_LEVEL_LOOKUP_CHANNEL.flatten().map{
    file ->
        def key = file.name.toString().replaceAll(/_levelLookup\.rds/,"")
        return tuple(key,file)
}
STEP_04_LEVEL_RES_KEY_CHANNEL = STEP_04_LEVEL_RES_CHANNEL.flatten().map{
    file ->
        def key = file.name.toString().replaceAll(/_levelRes\.rds/,"")
        return tuple(key,file)
}
STEP_04_LEVEL_RES_KEY_CHANNEL.join(STEP_04_LEVEL_LOOKUP_KEY_CHANNEL).join(STEP_04_LEVEL_EXPRS_KEY_CHANNEL).set{EXPERIMENTAL_UNIT_CHANNEL}

process grow_forest {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "large_cpu"

    input:
        file active_channels from file("${params.active_channels_path}")
        set val(key),file(res),file(lookup),file(exprs) from EXPERIMENTAL_UNIT_CHANNEL
        file analysis_map from STEP_04_ANALYSIS_MAP_CHANNEL

    output:
        set file("${key}_${params.starting_cell_pop}_pAnnF.rds"), file("${key}_${params.starting_cell_pop}_annF.rds") into STEP_05_EU_ANNOTATION_CHANNEL
        file analysis_map into STEP_05_ANALYSIS_MAP_CHANNEL
        file(exprs) into STEP_09_EU_CHANNEL
        set val(key),file(res),file(lookup),file(exprs) into STEP_11_EU_CHANNEL

    script:
        """
        #!/usr/bin/env Rscript
        
        faust:::nf_step_04_grow_forest_for_eu(activeChannelsPath="${active_channels}",
                                              experimentalUnit="${key}",
                                              startingCellPop="${params.starting_cell_pop}",
                                              threadNumber=${params.thread_number})
        """
}

// -----------------------------------------------------------------------------
// step 05
// -----------------------------------------------------------------------------
supervised_list_ch = Channel.fromPath("${params.supervised_list_path}")
process select_channels {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"

    input:
        file analysis_map from STEP_05_ANALYSIS_MAP_CHANNEL
        file (annotation_files) from STEP_05_EU_ANNOTATION_CHANNEL.collect()
        file supervised_list from supervised_list_ch

    output:
        set file(supervised_list), file(analysis_map), file("scoreMat.rds"), file("depthMat.rds"), file("initSelC.rds") into STEP_06_CONSTRUCTED_FILES_CHANNEL
        file annotation_files into STEP_06_EU_ANNOTATION_CHANNEL

    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_05_select_channels(startingCellPop="${params.starting_cell_pop}",
                                           depthScoreThreshold=${params.depth_score_threshold},
                                           selectionQuantile=${params.selection_quantile})
        """
}

// -----------------------------------------------------------------------------
// step 06
// -----------------------------------------------------------------------------
process reconcile_annotation_boundaries {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"

    input: 
        set file(supervised_list), file(analysis_map), file(score_mat), file(depth_mat), file(initselc) from STEP_06_CONSTRUCTED_FILES_CHANNEL
        file annotation_files from STEP_06_EU_ANNOTATION_CHANNEL.collect()

    output:
        set file(analysis_map),file("forceList.rds"),file("${params.starting_cell_pop}_rawGateList.rds"), file("${params.starting_cell_pop}_resListPrep.rds"),file("${params.starting_cell_pop}_selectedChannels.rds"),file("${params.starting_cell_pop}_resList.rds"),file("possibilityList.rds") into STEP_07_CREATED_FILES
        file(score_mat) into STEP_08_SCORE_MAT_CHANNEL

    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_06_reconcile_annotation_boundaries(supervisedListPath="${supervised_list}",
                                                           startingCellPop="${params.starting_cell_pop}")
        """
} 
// -----------------------------------------------------------------------------
// step 07
// -----------------------------------------------------------------------------
process make_annotation_matrices {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"

    input:
        set file(analysis_map),file(force_list),file(raw_gate_list), file(res_list_prep),file(selected_channels),file(res_list),file(possibility_list) from STEP_07_CREATED_FILES
        file samples from STEP_07_SAMPLE_CHANNEL.collect()

    output:
        file '*_annotationMatrix.csv' into STEP_08_ANNOTATION_MATRICES_CHANNEL
        file(force_list) into STEP_08_FORCE_LIST_CHANNEL
        set file(res_list), file(analysis_map),file(selected_channels) into STEP_09_FILES
        file samples into STEP_10_SAMPLE_CHANNEL
        file '*_annotationMatrix.csv' into STEP_12_ANNOTATION_MATRICES_CHANNEL

    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_07_make_annotation_matrices(startingCellPop="${params.starting_cell_pop}")
        """
}
// -----------------------------------------------------------------------------
// step 08
// -----------------------------------------------------------------------------
process plot_score_lines {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"
    
    input:
        file(force_list) from STEP_08_FORCE_LIST_CHANNEL
        file(score_mat) from STEP_08_SCORE_MAT_CHANNEL

    output:
        file "scoreLines.pdf" into SCORE_LINES_CH

    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_08_plot_score_lines(depthScoreThreshold=${params.depth_score_threshold},
                                            selectionQuantile=${params.selection_quantile})
        """
}

// -----------------------------------------------------------------------------
// step 09
// -----------------------------------------------------------------------------
process plot_marker_histograms {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"
    
    input:
        set file(res_list), file(analysis_map),file(selected_channels) from STEP_09_FILES
        file(all_eu_files) from STEP_09_EU_CHANNEL.collect()

    output:
        set file(analysis_map), file(res_list), file(selected_channels) into STEP_10_FILE_CHANNEL
        file "hist_*.pdf" into MARKER_HIST_CH
    
    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_09_plot_marker_histograms(startingCellPop="${params.starting_cell_pop}")
        """
}

// -----------------------------------------------------------------------------
//step 10
// -----------------------------------------------------------------------------
STEP_10_SAMPLE_TUPLE_CHANNEL = STEP_10_SAMPLE_CHANNEL.flatten().map{ 
    file -> 
    def sample_name = file.name.toString().replaceAll(/_exprsMat\.rds/,"")
    return tuple(sample_name, file)
}
STEP_10_DATA_CHANNEL = STEP_10_SAMPLE_TUPLE_CHANNEL.combine(STEP_10_FILE_CHANNEL)
process plot_sample_histograms {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"

    input:
        set val(sample_name),file(sample_file),file(analysis_map), file(res_list), file(selected_channels) from STEP_10_DATA_CHANNEL

    output:
        file "${sample_name}.pdf" into SAMPLE_HIST_CH
        set file(analysis_map),file(selected_channels),file(res_list) into STEP_11_GLOBAL_CHANNEL
    
    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_10_plot_sample_histograms(sampleName="${sample_name}",
                                                  startingCellPop="${params.starting_cell_pop}")
        """
}

// -----------------------------------------------------------------------------
//step 11
// -----------------------------------------------------------------------------
process discover_populations {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "large_cpu"

    input:
        set val(key),file(res),file(lookup),file(exprs) from STEP_11_EU_CHANNEL
        set file(analysis_map),file(selected_channels),file(res_list) from STEP_11_GLOBAL_CHANNEL

    output:
        file("${key}_scampClusterLabels.rds") into STEP_12_CLUSTER_LABELS
        file("${key}_scampAnnotation.csv") into STEP_12_SCAMP_ANNOTATIONS
        set file(analysis_map),file(selected_channels),file(res_list) into STEP_12_FILES

    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_11_discover_populations_for_unit(experimentalUnit="${key}",
                                                         startingCellPop="${params.starting_cell_pop}",
                                                         nameOccuranceNum=${params.name_occurrence_number},
                                                         threadNumber=${params.thread_number})
        """
}

// -----------------------------------------------------------------------------
//step 12
// -----------------------------------------------------------------------------
process gate_clusters {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"
    
    input:
    file(sample_annotation_matrices) from STEP_12_ANNOTATION_MATRICES_CHANNEL.collect()
    file eu_cluster_labels from STEP_12_CLUSTER_LABELS.collect()
    file eu_scamp_annotations from STEP_12_SCAMP_ANNOTATIONS.collect()
    set file(analysis_map),file(selected_channels),file(res_list) from STEP_12_FILES.first()

    output:
    set file("scampNameSummary.rds"),file("scampClusterNames.rds"),file(selected_channels),file(analysis_map) into STEP_13_CHANNEL
    file("*_faustAnnotation.csv") into FAUST_SAMPLE_ANNOTATIONS_CH
    file("scampNamesPlot.pdf") into NAMES_PLOT_CH

    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_12_gate_clusters(startingCellPop="${params.starting_cell_pop}",
                                         nameOccuranceNum=${params.name_occurrence_number})
        """
}

// -----------------------------------------------------------------------------
//step 13
// -----------------------------------------------------------------------------
SAMPLE_ANN_CH = FAUST_SAMPLE_ANNOTATIONS_CH.flatten().unique().collect()
process make_count_matrix {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"

    input:
        set file(scamp_name_summary), file(scamp_cluster_names), file(selected_channels), file(analysis_map) from STEP_13_CHANNEL
        file(sample_faust_annotations) from SAMPLE_ANN_CH

    output:
        file("faustCountMatrix.rds") into COUNT_MATRIX_CH

    script:
        """
        #!/usr/bin/env Rscript

        faust:::nf_step_13_make_count_matrix(startingCellPop="${params.starting_cell_pop}")
        """
}

// -----------------------------------------------------------------------------
//step 14
// -----------------------------------------------------------------------------
process gather_results {
    // [ directives ]
    container "rglab/faust-nextflow-debug:0.0.1"
    label "micro_mem_and_cpu"
    publishDir "FAUST_RESULTS"

    input:
        file results from COUNT_MATRIX_CH.merge(NAMES_PLOT_CH).merge(MARKER_HIST_CH).merge(SCORE_LINES_CH).merge(SAMPLE_HIST_CH.collect()).flatten().collect()

    output:
        file results into OUTPUT

    script:
        """
        echo done
        """
}