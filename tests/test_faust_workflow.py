# Copyright 2020 Fred Hutchinson Cancer Research Center
################################################################################
### Python unittest to run Nextflow on test dataset

import sys
import os
import hashlib
import subprocess

import unittest

import numpy as np
import pandas as pd
#from s3fs import S3FileSystem

sys.path.insert(0,"/app/Lmod/lmod/lmod/init")
from env_modules_python import module
module('load','nextflow')


################################################################################

HUTCH_AWS_CONFIG = os.path.join(os.environ["HOME"], "hutch-overrides.config")
RGLAB_AWS_CONFIG = os.path.join(os.environ["HOME"], "rglab-queue.config")


#FAUST_NF = os.path.join(os.environ["HOME"], "hub/FAUST_Nextflow/main.nf")
FAUST_NF = "../main.nf"

TEST_OUT_DIR = "s3://fh-pi-.... "

# "lknecht-nextflow-test",
RGLAB_QUEUE = "krcurtis-faust-nextflow"
#BUCKET_TMP = "s3://lknecht-nextflow-test"
BUCKET_TMP = "s3://krcurtis-faust-nextflow"
HUTCH_BUCKET = "s3://TODO"


S3_LEGACY_GATING_SET = "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_001/"

S3_LEGACY_GATING_TESTSETS = [
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_001/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_003/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_005/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_011/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_023/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_047/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_115/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_160/",
    "s3://rglab-public-datasets/faust_nextflow_test_data_sets/legacy_flow_workspace_gating_sets/MB_361/",
]

CHANNEL_ACTIVE = os.path.join(os.environ["HOME"], "faust-test-data/gs_size_001MB/helper_files/activeChannels.rds")
CHANNEL_BOUND = os.path.join(os.environ["HOME"], "faust-test-data/gs_size_001MB/helper_files/channelBounds.rds")
CHANNEL_SUPERVISED = os.path.join(os.environ["HOME"], "faust-test-data/gs_size_001MB/helper_files/supervisedList.rds")


################################################################################


def invoke_system(cmd_params, log_to_file=None, verbose=True):
    cmd = ' '.join(cmd_params)
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, executable='/bin/bash')
    out_msg, err_msg = p.communicate()
    if verbose:
        print("stdout:", out_msg)
        print("stderr:", err_msg)
    if None != log_to_file:
        with open(log_to_file, 'at') as f_out:
            f_out.write("cmd" + str( cmd_params) + "\n")
            f_out.write("stdout:" + str(out_msg) +  "\n")
            f_out.write("stderr:" + str(err_msg) + "\n")
    errcode  = p.returncode
    if 0 != errcode:
        raise Exception("ERROR: failed (returns {errcode}):".format(errcode=errcode) + cmd + '\n' + err_msg.decode(encoding='utf-8') + '\n' + out_msg.decode(encoding='utf-8'))
    return True



class NextflowTest(unittest.TestCase):
    def clean_nextflow_dirs(self):
        #params = [ "aws", "s3", "rm", "--recursive", TEST_OUT_DIR]
        #os.system(" ".join(params))
        invoke_system(["rm", "-rf", "work", "faust_nextflow_report.html", "faust_nextflow_timeline.html", "trace.txt", ".nextflow", ".nextflow.log", "FAUST_RESULTS"])

    def setUp(self):
        self.clean_nextflow_dirs()

        
    def compare_results(self):
        self.assertTrue(False)
        #self.assertLessEqual ... (a,b,msg="unexpected differences for " + generated)


    def tst_hutch_config(self):
        #print("Pre-paring to run test")

        #"-resume", "-with-dag", "flowchart.png"]
        #os.chdir(os.path.dirname(FAUST_NF))

        params = ["nextflow", "run", FAUST_NF,
                  "-c", HUTCH_AWS_CONFIG,
                  "-profile",  "aws",
                  "--active_channels_path", CHANNEL_ACTIVE,
                  "--channel_bounds_path", CHANNEL_BOUND,
                  "--supervised_list_path", CHANNEL_SUPERVISED,
                  "--input_gating_set_directory", os.path.join(os.environ["HOME"], "faust-test-data/gs_size_001MB/legacy_gating_set"),
                  "--command", "generate_annotations",
                  "-bucket-dir", HUTCH_BUCKET,
                  "-with-report", "faust_nextflow_report.html",
                  "-with-timeline", "faust_nextflow_timeline.html",
                  "-with-trace"]


        invoke_system(params, log_to_file="logs.txt")


    def tst_basic_with_config(self):
        #print("Pre-paring to run test")

        #"-resume", "-with-dag", "flowchart.png"]
        #os.chdir(os.path.dirname(FAUST_NF))

        params = ["nextflow", "run", FAUST_NF,
                  "-c", RGLAB_AWS_CONFIG,
                  #"-process.queue", QUEUE,
                  "-profile",  "aws",
                  "--active_channels_path", CHANNEL_ACTIVE,
                  "--channel_bounds_path", CHANNEL_BOUND,
                  "--supervised_list_path", CHANNEL_SUPERVISED,
                  "--input_gating_set_directory", os.path.join(os.environ["HOME"], "faust-test-data/gs_size_001MB/legacy_gating_set"),
                  "--command", "generate_annotations",
                  "-bucket-dir", BUCKET_TMP,
                  "-with-report", "faust_nextflow_report.html",
                  "-with-timeline", "faust_nextflow_timeline.html",
                  "-with-trace"]


        invoke_system(params, log_to_file="logs.txt")

    def tst_basic_with_queue(self):
        #print("Pre-paring to run test")

        #"-resume", "-with-dag", "flowchart.png"]
        #os.chdir(os.path.dirname(FAUST_NF))

        params = ["nextflow", "run", FAUST_NF,
                  "-process.queue", RGLAB_QUEUE,
                  "-profile",  "aws",
                  "--active_channels_path", CHANNEL_ACTIVE,
                  "--channel_bounds_path", CHANNEL_BOUND,
                  "--supervised_list_path", CHANNEL_SUPERVISED,
                  "--input_gating_set_directory", os.path.join(os.environ["HOME"], "faust-test-data/gs_size_001MB/legacy_gating_set"),
                  "--command", "generate_annotations",
                  "-bucket-dir", BUCKET_TMP,
                  "-with-report", "faust_nextflow_report.html",
                  "-with-timeline", "faust_nextflow_timeline.html",
                  "-with-trace"]


        invoke_system(params, log_to_file="logs.txt")

    def test_basic_with_s3_gating_set(self):
        #print("Pre-paring to run test")

        #"-resume", "-with-dag", "flowchart.png"]
        #os.chdir(os.path.dirname(FAUST_NF))

        params = ["nextflow", "run", FAUST_NF,
                  "-process.queue", RGLAB_QUEUE,
                  "-profile",  "aws",
                  "--active_channels_path", CHANNEL_ACTIVE,
                  "--channel_bounds_path", CHANNEL_BOUND,
                  "--supervised_list_path", CHANNEL_SUPERVISED,
                  "--input_gating_set_directory", S3_LEGACY_GATING_SET,
                  "--command", "generate_annotations",
                  "-bucket-dir", BUCKET_TMP,
                  "-with-report", "faust_nextflow_report.html",
                  "-with-timeline", "faust_nextflow_timeline.html",
                  "-with-trace"]


        invoke_system(params, log_to_file="logs.txt")

    def tst_basic_gating_sets(self):
        #print("Pre-paring to run test")

        #"-resume", "-with-dag", "flowchart.png"]
        #os.chdir(os.path.dirname(FAUST_NF))

        for gating_set in S3_LEGACY_GATING_TESTSETS:
            print(gating_set)
            self.clean_nextflow_dirs()

            params = ["nextflow", "run", FAUST_NF,
                      "-process.queue", RGLAB_QUEUE,
                      "-profile",  "aws",
                      "--active_channels_path", CHANNEL_ACTIVE,
                      "--channel_bounds_path", CHANNEL_BOUND,
                      "--supervised_list_path", CHANNEL_SUPERVISED,
                      "--input_gating_set_directory", gating_set,
                      "--command", "generate_annotations",
                      "-bucket-dir", BUCKET_TMP,
                      "-with-report", "faust_nextflow_report.html",
                      "-with-timeline", "faust_nextflow_timeline.html",
                      "-with-trace"]

            invoke_system(params, log_to_file="logs.txt")
