include { clusterExperimentalUnitsWithScamp } from "./processes/cluster_experimental_units_with_scamp.nf"
include { finalizeFAUSTAnnotationData } from "./processes/finalize_faust_annotation_data.nf"
include { gateScampClusters } from "./processes/gate_scamp_clusters.nf"
include { growAnnotationForest } from "./processes/grow_annotation_forest.nf"
include { plotPhenotypeFilter } from "./processes/plot_phenotype_filter.nf"
include { prepareFAUSTData } from "./processes/prepare_faust_data.nf"

nextflow.preview.dsl=2

workflow discoverPhenotypes {
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
    take: name_occurrence_number
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
        // -----
        clusterExperimentalUnitsWithScamp(finalizeFAUSTAnnotationData.out.metadata_directory,
                                          finalizeFAUSTAnnotationData.out.samples_data_directory,
                                          prepareFAUSTData.out.experimental_unit_directories.flatten(),
                                          finalizeFAUSTAnnotationData.out.gate_data_directory,
                                          starting_cell_population,
                                          name_occurrence_number,
                                          plotting_device,
                                          project_path,
                                          debug_flag,
                                          thread_number,
                                          seed_value)

        plotPhenotypeFilter(clusterExperimentalUnitsWithScamp.out.metadata_directory.first(),
                            clusterExperimentalUnitsWithScamp.out.experimental_units_directory.toList(),
                            name_occurrence_number,
                            plotting_device,
                            project_path,
                            debug_flag)


        gateScampClusters(plotPhenotypeFilter.out.metadata_directory,
                          clusterExperimentalUnitsWithScamp.out.samples_data_directory.collect(),
                          finalizeFAUSTAnnotationData.out.gate_data_directory,
                          project_path,
                          debug_flag)
}