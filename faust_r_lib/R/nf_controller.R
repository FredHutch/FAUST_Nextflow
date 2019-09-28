nf_controller <- function(
                          projectPath,
                          gatingSetPath,
                          channelBoundsPath,
                          supervisedListPath,
                          experimentalUnit,
                          imputationHierarchy,
                          activeChannelsPath,
                          startingCellPop,
                          depthScoreThreshold,
                          selectionQuantile,
                          threadNumber
                          )
{
    faust:::nf_step_00_initialize_faust_data(
               gatingSetPath=gatingSetPath,
               experimentalUnit=experimentalUnit,
               imputationHierarchy=imputationHierarchy
           )

    faust:::nf_step_01_extract_data_from_gs(
               gatingSetPath=gatingSetPath,
               activeChannelsPath=activeChannelsPath,
               startingCellPop=startingCellPop,
           )

    faust:::nf_step_02_make_restriction_matrices(
               gatingSetPath=gatingSetPath,
               channelBoundsPath=channelBoundsPath,
               projectPath=projectPath
           )

    faust:::nf_step_03_make_experimental_units(
           )

    allExperimentalUnits <- list.files(paste0(projectPath,"/faustData/levelData"))
    for (experimentalUnit in allExperimentalUnits) {
        print(paste0("Growing forest for ",experimentalUnit))
        faust:::nf_step_04_grow_forest_for_eu(
                   experimentalUnit=experimentalUnit,
                   startingCellPop=startingCellPop,
                   activeChannelsPath=activeChannelsPath,
                   threadNumber=threadNumber
               )
    }

    faust:::nf_step_05_select_channels(
               startingCellPop=startingCellPop,
               depthScoreThreshold=depthScoreThreshold,
               selectionQuantile=selectionQuantile
           )

    faust:::nf_step_06_reconcile_annotation_boundaries(
               supervisedListPath=supervisedListPath,
               startingCellPop=startingCellPop
           )

    faust:::nf_step_07_make_annotation_matrices(
               startingCellPop=startingCellPop
           )

    faust:::nf_step_08_plot_score_lines(
               depthScoreThreshold=depthScoreThreshold,
               selectionQuantile=selectionQuantile
           )

    faust:::nf_step_09_plot_marker_histograms(
               startingCellPop=startingCellPop
           )

    
    allSampleNames <- list.files(paste0(projectPath,"/faustData/sampleData"))
    for (sampleName in allSampleNames) {
        print(paste0("Drawing annotation histograms for ",sampleName))
        faust:::nf_step_10_plot_sample_histograms(
                   sampleName=sampleName,
                   startingCellPop=startingCellPop
               )
    }


    allExperimentalUnits <- list.files(paste0(projectPath,"/faustData/levelData"))
    for (experimentalUnit in allExperimentalUnits) {
        print(paste0("Discovering phenotypes for ",experimentalUnit))
        faust:::nf_step_11_discover_populations_for_unit(
                   experimentalUnit=experimentalUnit,
                   startingCellPop=startingCellPop, 
                   nameOccuranceNum=nameOccuranceNum,
                   threadNumber=threadNumber
               )
    }

    faust:::nf_step_12_gate_clusters(
               startingCellPop=startingCellPop,
               nameOccuranceNum=nameOccuranceNum
            )

    faust:::nf_step_13_make_count_matrix (
                startingCellPop=startingCellPop
           )
}
