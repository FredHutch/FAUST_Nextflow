# Copyright 2020 Fred Hutchinson Cancer Research Center

# ------------------------------------------------------------------------------
# Python Standard Libraries
# ------------------------------------------------------------------------------
from enum import Enum
import os
import subprocess
import time
# ------------------------------------------------------------------------------
# Third-Party Libraries
# ------------------------------------------------------------------------------
import pytest
# ------------------------------------------------------------------------------
# Custom Libraries
# ------------------------------------------------------------------------------
# N/A

# ------------------------------------------------------------------------------
# Configure Environment
# ------------------------------------------------------------------------------
# Used because we want missing environment variables to fail loudly


def getEnvironmentVariable(variable_name):
    try:
        return os.environ[variable_name]
    except KeyError:
        error_message = ("Environment Variable Key: {}"
                         " The requested environment variable was not set."
                         " Please make sure that it is available for the"
                         " runtime environment and try again.").format(variable_name)
        raise NotImplementedError(error_message)


SCRIPT_ABSOLUTE_FILE_PATH = os.path.realpath(__file__)
SCRIPT_ABSOLUTE_DIRECTORY_PATH = os.path.dirname(SCRIPT_ABSOLUTE_FILE_PATH)
REPOSITORY_ROOT_ABSOLUTE_DIRECTORY_PATH = os.path.realpath(os.path.join(SCRIPT_ABSOLUTE_DIRECTORY_PATH, ".."))

NEXTFLOW_EXECUTABLE_ABSOLUTE_FILE_PATH = os.path.join(REPOSITORY_ROOT_ABSOLUTE_DIRECTORY_PATH, "nextflow")
FAUST_NEXTFLOW_MAIN_ABSOLUTE_FILE_PATH = os.path.join(REPOSITORY_ROOT_ABSOLUTE_DIRECTORY_PATH, "main.nf")

AMAZON_BATCH_PROCESS_QUEUE_NAME = getEnvironmentVariable("FAUST_NEXTFLOW_TESTING_BATCH_PROCESS_QUEUE_NAME")
AMAZON_S3_BUCKET_NAME = os.path.join("s3://", getEnvironmentVariable("FAUST_NEXTFLOW_TESTING_AMAZON_S3_BUCKET_NAME"))

S3_LEGACY_GATING_SETS_DIRECTORY_PATH = getEnvironmentVariable("FAUST_NEXTFLOW_TESTING_AMAZON_S3_VALID_LEGACY_GATING_SETS_DIRECTORY_PATH")
VALID_S3_LEGACY_GATING_SETS = [
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_001"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_003"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_005"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_011"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_023"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_047"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_115"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_160"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "MB_361"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "GB_001"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "GB_002"),
    os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH, "GB_028"),
]

S3_GATING_SETS_DIRECTORY_PATH = getEnvironmentVariable("FAUST_NEXTFLOW_TESTING_AMAZON_S3_VALID_GATING_SETS_DIRECTORY_PATH")
VALID_S3_GATING_SETS = [
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "KB_769"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_001"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_003"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_005"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_011"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_023"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_047"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_115"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_160"),
    os.path.join(S3_GATING_SETS_DIRECTORY_PATH, "MB_361"),
]

ACTIVE_CHANNELS_ABSOLUTE_FILE_PATH = os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH,
                                                  "helper_files",
                                                  "active_channels.rds")
CHANNEL_BOUNDS_ABSOLUTE_FILE_PATH = os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH,
                                                 "helper_files",
                                                 "channel_bounds.rds")
SUPERVISED_LIST_ABSOLUTE_FILE_PATH = os.path.join(S3_LEGACY_GATING_SETS_DIRECTORY_PATH,
                                                  "helper_files",
                                                  "supervised_list.rds")

FAUST_NEXTFLOW_TESTING_LOG_FILE_NAME = "FAUST_NEXTFLOW_TESTING_LOG.log"
FAUST_NEXTFLOW_TESTING_LOG_FILE_ABSOLUTE_PATH = os.path.join(SCRIPT_ABSOLUTE_DIRECTORY_PATH, FAUST_NEXTFLOW_TESTING_LOG_FILE_NAME)


class FAUSTNextflowExecutionProfile(Enum):
    LOCAL = "local"
    AWS = "aws"


class FAUSTCommand(Enum):
    GENERATE_ANNOTATIONS = "generate_annotations"
    DISCOVER_PHENOTYPES = "discover_phenotypes"


def generateFAUSTCommandArguments(nextflow_executable_absolute_file_path,
                                  faust_nextflow_main_absolute_file_path,
                                  input_gating_set_absolute_directory_path,
                                  active_channels_absolute_file_path,
                                  channel_bounds_absolute_file_path,
                                  supervised_list_absolute_file_path,
                                  faust_command,
                                  execution_profile=FAUSTNextflowExecutionProfile.AWS,
                                  amazon_batch_process_queue_name=None,
                                  amazon_s3_bucket_name=None,
                                  override_configuration_file_path=None):
    # DEFAULT ASSUMPTION: Assumes that we are doing AWS by default, do not
    #                       change this assumption
    parameters_to_return = []
    # ------------------------------
    # Nextflow Specific Configurations
    # ------------------------------
    parameters_to_return.append("sh")
    parameters_to_return.append(nextflow_executable_absolute_file_path)
    parameters_to_return.append("run")
    parameters_to_return.append(faust_nextflow_main_absolute_file_path)
    # ---
    if(override_configuration_file_path is not None):
        parameters_to_return.append("-c")
        parameters_to_return.append(override_configuration_file_path)
    # ---
    # Default to AWS execution
    parameters_to_return.append("-profile")
    if(execution_profile == FAUSTNextflowExecutionProfile.AWS):
        parameters_to_return.append(FAUSTNextflowExecutionProfile.AWS.value)
    elif(execution_profile == FAUSTNextflowExecutionProfile.AWS):
        parameters_to_return.append(FAUSTNextflowExecutionProfile.LOCAL.value)
    # ---
    parameters_to_return.append("-with-report")
    parameters_to_return.append("faust_nextflow_report.html")
    # ---
    parameters_to_return.append("-with-timeline")
    parameters_to_return.append("faust_nextflow_timeline.html")
    # ---
    parameters_to_return.append("-with-trace")
    # ------------------------------
    # AWS Configurations
    # ------------------------------
    parameters_to_return.append("-bucket-dir")
    parameters_to_return.append(amazon_s3_bucket_name)
    # ---
    parameters_to_return.append("-process.queue")
    parameters_to_return.append(amazon_batch_process_queue_name)
    # ------------------------------
    # FAUST Specific Configurations
    # ------------------------------
    parameters_to_return.append("--command")
    if(faust_command == FAUSTCommand.GENERATE_ANNOTATIONS):
        parameters_to_return.append(FAUSTCommand.GENERATE_ANNOTATIONS.value)
    elif(faust_command == FAUSTCommand.DISCOVER_PHENOTYPES):
        parameters_to_return.append(FAUSTCommand.DISCOVER_PHENOTYPES.value)
    # ---
    parameters_to_return.append("--input_gating_set_directory")
    parameters_to_return.append(input_gating_set_absolute_directory_path)
    # ---
    parameters_to_return.append("--active_channels_path")
    parameters_to_return.append(active_channels_absolute_file_path)
    # ---
    parameters_to_return.append("--channel_bounds_path")
    parameters_to_return.append(channel_bounds_absolute_file_path)
    # ---
    parameters_to_return.append("--supervised_list_path")
    parameters_to_return.append(supervised_list_absolute_file_path)

    return parameters_to_return


def run_command(command_arguments, log_file_absolute_path=None, verbose=True):
    # Use this to debug nextflow execution minimum path
    # command_to_run = " ".join([NEXTFLOW_EXECUTABLE_ABSOLUTE_FILE_PATH, "-h"])
    command_to_run = " ".join(command_arguments)

    process_start_time = time.time()
    completed_process = subprocess.run(command_to_run,
                                       shell=True,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       executable="/bin/bash")

    completed_process_arguments = completed_process.args
    completed_process_standard_out = completed_process.stdout
    completed_process_standard_error = completed_process.stderr
    completed_process_return_code = completed_process.returncode
    completed_process_start_time = convertTimeToString(process_start_time)
    completed_process_total_duration_in_seconds = round(time.time() - process_start_time)

    if verbose:
        print("stdout:", completed_process.stdout)
        print("stderr:", completed_process.stderr)

    if log_file_absolute_path is not None:
        with open(log_file_absolute_path, "at") as file_handle:
            file_handle.write(("=" * 80) + "\n")
            file_handle.write("Command Run: " + str(command_arguments) + "\n")
            file_handle.write("Completed Process Return Code: " + str(completed_process_return_code) + "\n")
            file_handle.write("Completed Process Start Time: " + str(completed_process_start_time) + "\n")
            file_handle.write("Completed Process Duration (in seconds): " + str(completed_process_total_duration_in_seconds) + "\n")
            file_handle.write("Completed Process Arguments: " + str(completed_process_arguments) + "\n")
            file_handle.write("Completed Process Standard Out: " + str(completed_process_standard_out) + "\n")
            file_handle.write("Completed Process Standard Error: " + str(completed_process_standard_error) + "\n")

    data_to_return = {
        "arguments": completed_process_arguments,
        "duration_in_seconds": completed_process_total_duration_in_seconds,
        "return_code": completed_process_return_code,
        "start_time": process_start_time,
        "standard_error": completed_process_standard_error,
        "standard_out": completed_process_standard_out,
    }
    return data_to_return


def clean_nextflow_dirs(self):
    run_command(["rm",
                 "-rf",
                 "work",
                 "faust_nextflow_report.html",
                 "faust_nextflow_timeline.html",
                 "trace.txt",
                 ".nextflow",
                 ".nextflow.log",
                 "FAUST_RESULTS"],
                log_file_absolute_path=FAUST_NEXTFLOW_TESTING_LOG_FILE_ABSOLUTE_PATH)


def convertTimeToString(time_to_convert):
    format = "%Y-%m-%d %H:%M:%S"
    converted_string = time.strftime(format, time.localtime(time_to_convert))
    return converted_string


# ------------------------------------------------------------------------------
# Testing Logic
# ------------------------------------------------------------------------------
@pytest.mark.parametrize("input_gating_set_absolute_directory_path", VALID_S3_LEGACY_GATING_SETS)
def test_valid_legacy_gating_sets(input_gating_set_absolute_directory_path):
    faust_command_arguments = generateFAUSTCommandArguments(NEXTFLOW_EXECUTABLE_ABSOLUTE_FILE_PATH,
                                                            FAUST_NEXTFLOW_MAIN_ABSOLUTE_FILE_PATH,
                                                            input_gating_set_absolute_directory_path,
                                                            ACTIVE_CHANNELS_ABSOLUTE_FILE_PATH,
                                                            CHANNEL_BOUNDS_ABSOLUTE_FILE_PATH,
                                                            SUPERVISED_LIST_ABSOLUTE_FILE_PATH,
                                                            FAUSTCommand.GENERATE_ANNOTATIONS,
                                                            execution_profile=FAUSTNextflowExecutionProfile.AWS,
                                                            amazon_batch_process_queue_name=AMAZON_BATCH_PROCESS_QUEUE_NAME,
                                                            amazon_s3_bucket_name=AMAZON_S3_BUCKET_NAME)
    command_output = run_command(faust_command_arguments, log_file_absolute_path=FAUST_NEXTFLOW_TESTING_LOG_FILE_ABSOLUTE_PATH)
    assert command_output["return_code"] == 0, command_output["standard_error"]


@pytest.mark.parametrize("input_gating_set_absolute_directory_path", VALID_S3_GATING_SETS)
def test_valid_gating_sets(input_gating_set_absolute_directory_path):
    faust_command_arguments = generateFAUSTCommandArguments(NEXTFLOW_EXECUTABLE_ABSOLUTE_FILE_PATH,
                                                            FAUST_NEXTFLOW_MAIN_ABSOLUTE_FILE_PATH,
                                                            input_gating_set_absolute_directory_path,
                                                            ACTIVE_CHANNELS_ABSOLUTE_FILE_PATH,
                                                            CHANNEL_BOUNDS_ABSOLUTE_FILE_PATH,
                                                            SUPERVISED_LIST_ABSOLUTE_FILE_PATH,
                                                            FAUSTCommand.GENERATE_ANNOTATIONS,
                                                            execution_profile=FAUSTNextflowExecutionProfile.AWS,
                                                            amazon_batch_process_queue_name=AMAZON_BATCH_PROCESS_QUEUE_NAME,
                                                            amazon_s3_bucket_name=AMAZON_S3_BUCKET_NAME)
    command_output = run_command(faust_command_arguments, log_file_absolute_path=FAUST_NEXTFLOW_TESTING_LOG_FILE_ABSOLUTE_PATH)
    assert command_output["return_code"] == 0, command_output["standard_error"]


# def test_configuration_overrides(input_gating_set_absolute_directory_path):
#     # TODO: Implement
#     pass
