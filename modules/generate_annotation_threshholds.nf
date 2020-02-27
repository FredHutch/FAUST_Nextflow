include { prepareFAUSTData } from "./processes/prepare_faust_data.nf"
include { growAnnotationForest } from "./processes/grow_annotation_forest.nf"
include { finalizeFAUSTAnnotationData } from "./processes/finalize_faust_annotation_data.nf"

nextflow.preview.dsl=2

workflow generateAnnotationThreshholds {
    // FAUST - Required Execution Parameters
    take: input_gating_set_directory_channel
    take: active_channels_path_channel
    take: channel_bounds_path_channel
    take: supervised_list_path_channel
    // FAUST - Optional Execution Parameters
    take: imputation_heirarchy
    take: experimental_unit
    take: starting_cell_population
    take: depth_score_threshold
    take: selection_quantile
    take: plotting_device
    // FAUST - Optional Execution Management Parameters
    take: project_path
    take: debug_flag
    take: thread_number
    take: seed_value

    main:
        prepareFAUSTData(input_gating_set_directory_channel,
                         active_channels_path_channel,
                         channel_bounds_path_channel,
                         supervised_list_path_channel,
                         imputation_heirarchy,
                         experimental_unit,
                         starting_cell_population,
                         project_path,
                         debug_flag)
        // -----
        growAnnotationForest(active_channels_path_channel.first(),
                             prepareFAUSTData.out.metadata_directory.first(),
                             prepareFAUSTData.out.experimental_unit_directories.flatten(),
                             starting_cell_population,
                             thread_number,
                             seed_value,
                             project_path,
                             debug_flag)
        // -----
        finalizeFAUSTAnnotationData(prepareFAUSTData.out.metadata_directory.first(),
                          prepareFAUSTData.out.samples_data_directory.first(),
                          growAnnotationForest.out.experimental_unit_directory.collect(),
                          depth_score_threshold,
                          selection_quantile,
                          plotting_device,
                          project_path,
                          debug_flag)
}
