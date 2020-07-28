nextflow.preview.dsl=2

include { generateAnnotationThreshholds } from "./modules/generate_annotation_threshholds.nf"
include { discoverPhenotypes } from "./modules/discover_phenotypes.nf"

// Function which prints help message text
def helpMessage() {
    log.info"""
    Usage:
    nextflow run FredHutch/FAUST_Nextflow <ARGUMENTS>
    TODO

    Required Arguments:
    TODO

    Statistical Arguments:
    TODO

    Execution Arguments:
    TODO

    Nextflow Specific Arguments:
    TODO
    """.stripIndent()
}
// Show the help message if the user doesn't specify ANY parameters
total_parameters_provided_by_user = params.size()
if(total_parameters_provided_by_user == 0) {
    helpMessage()
    exit 0
}

// FAUST Required
params.input_gating_set_directory = "$baseDir/input"

// FAUST Optional
params.channel_bounds_path = ""
params.active_channels_path = ""
params.supervised_list_path = ""
params.imputation_hierarchy = ""
params.experimental_unit = "name"
params.starting_cell_population = "root"
params.project_path = "."
params.depth_score_threshold = 0.01
params.selection_quantile = 0.50
params.name_occurrence_number = 0
params.debug_flag = "FALSE"
params.thread_number = 1
params.seed_value = 123
params.draw_annotation_histograms = "TRUE"
params.annotations_approved = "FALSE"
params.plotting_device = "pdf"

//  Nextflow Specific Execution Parameters
params.command = "USER_DID_NOT_PROVIDE_COMMAND"
params.help = "" // For help message

generate_annotations_command = "generate_annotations"
discover_phenotypes_command = "discover_phenotypes"
valid_commands = [generate_annotations_command, discover_phenotypes_command]

// Show help message if the user specifies the --help flag at runtime
if (params.help){
    helpMessage()
    exit 0
}

workflow {
    // Directives
    // N/A

    input:
        // Required
        input_gating_set_directory = Channel.fromPath(params.input_gating_set_directory)
        // Optional - reasonable defaults if missing. 
        if(params.active_channels_path){
            active_channels_path = Channel.fromPath(params.active_channels_path)
        }else{
            active_channels_path = Channel.empty().ifEmpty("")
        }
        if(params.channel_bounds_path){
            channel_bounds_path = Channel.fromPath(params.channel_bounds_path)
        }else{
            channel_bounds_path = Channel.empty().ifEmpty("")
        }
        if(params.supervised_list_path){
            supervised_list_path = Channel.fromPath(params.supervised_list_path)
        }else{
            supervised_list_path = Channel.empty().ifEmpty("")
        }
        // Optional - Statistical
        starting_cell_population = params.starting_cell_population
        imputation_hierarchy = params.imputation_hierarchy
        experimental_unit = params.experimental_unit
        depth_score_threshold = params.depth_score_threshold
        selection_quantile = params.selection_quantile
        plotting_device = params.plotting_device
        name_occurrence_number = params.name_occurrence_number
        // Optional - Execution Specific
        project_path = params.project_path
        debug_flag = params.debug_flag
        thread_number = params.thread_number
        seed_value = params.seed_value
        // Nextflow Specific Execution Parameters
        command = params.command


    // Short-circuit and exit
    is_command_valid = valid_commands.contains(command)
    if(!is_command_valid) {
        incorrect_command_provided_error_message = "`${command}` was the provided command. However it is NOT a valid command. Please select from one of the valid commands: ${valid_commands}. Then re-run this workflow with with the `--command <COMMAND>` parameter provided."
        throw new Exception(incorrect_command_provided_error_message)
    }

    if(command == generate_annotations_command) {
        // TODO: Validation steps were removed - add them back?
        generateAnnotationThreshholds(input_gating_set_directory,
                                      active_channels_path,
                                      channel_bounds_path,
                                      supervised_list_path,
                                      // -----
                                      imputation_hierarchy,
                                      experimental_unit,
                                      starting_cell_population,
                                      depth_score_threshold,
                                      selection_quantile,
                                      plotting_device,
                                      // -----
                                      project_path,
                                      debug_flag,
                                      thread_number,
                                      seed_value)
    }

    if(command == discover_phenotypes_command) {
        // TODO: Validation steps were removed - add them back?
        discoverPhenotypes(input_gating_set_directory,
                           active_channels_path,
                           channel_bounds_path,
                           supervised_list_path,
                           // -----
                           imputation_hierarchy,
                           experimental_unit,
                           starting_cell_population,
                           depth_score_threshold,
                           selection_quantile,
                           name_occurrence_number,
                           plotting_device,
                           // -----
                           project_path,
                           debug_flag,
                           thread_number,
                           seed_value)
    }
}
