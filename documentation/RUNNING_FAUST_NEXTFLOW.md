# Overview

This repo contains a `Nextflow` implementation of the `FAUST` statistical method.

`FAUST` is an amazing new technique that will help create higher quality analysis of data sets by [TODO @EGreene please explain better than me]

# Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Repository Structure](#repository-structure)
- [Building](#building)
- [Build the FAUST Docker Image](#build-the-faust-docker-image)
- [Configurations](#configurations)
  - [Data Set Pre-processing](#data-set-pre-processing)
    - [Active Channels File](#active-channels-file)
    - [Channel Bounds File](#channel-bounds-file)
    - [Supervised List File](#supervised-list-file)
  - [AWS Configurations](#aws-configurations)
- [Running](#running)
  - [Locally](#locally)
  - [Command Template](#command-template)
  - [Command Example](#command-example)
  - [Using AWS Batch](#using-aws-batch)
    - [Command Template](#command-template-1)
    - [Command Example](#command-example-1)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Repository Structure

| Name                   | Description                                                                                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| README.md              | This document to explain how to use the `FAUST` `Nextflow` implementation                                                                                                              |
| continuous_integration | This is the directory that contains all the required files to make `FAUST` Nextflow available for everyone. Users of `FAUST`'s Nextflow implementation should not need to look in here |
| main.nf                | This is the `Nextflow` script for `FAUST`                                                                                                                                              |
| faust_r_lib            | This is a one off implementation of `FAUST` in order to simplify supporting `Nextflow`                                                                                                 |
| nextflow.config        | This is the configuration file for `Nextflow`                                                                                                                                          |

# Building

> ⚠️ **Warning**: Users of `FAUST` `Nextflow` do not need to pay attention to this section!

# Build the FAUST Docker Image

1. Add your GitHub Personal Access Token to the current environment
    - `export GITHUB_PAT=PLEASE_ENTER_YOUR_TOKEN_HERE`
1. Run the script to build the docker image
    - ⚠️ **Warning** Perform this command from the repository root directory
    - `sh continuous_integration/build_docker_images.sh`
1. Push the Docker Image to Docker Hub's registry
    - ⚠️ **Warning** Perform this command from the repository root directory
    - `sh continuous_integration/deploy_docker_images.sh`

# Configurations

## Data Set Pre-processing

1. First get a data set that you'd like to process
1. Pre-process this data set
    - Convert it into a gating set
    - Gate out doublets
    - Gate out
1. Save the gating set to a directory
1. Create an active channels file
    - See the `active channels file` section for more information
1. Create a `channel bounds file`
    - See the `channel bounds file` section for more information
1. Create a `supervised list file`
    - See the `supervised list file` section for more information

### Active Channels File

@Egreene - please explain what is required in this file

### Channel Bounds File

@Egreene - please explain what is required in this file

### Supervised List File

@Egreene - please explain what is required in this file

## AWS Configurations

1. Create a VPC in AWS
1. Create an AWS ami
1. Create an AWS S3 bucket
1. Create an AWS Batch compute environment
1. Create an AWS Batch queue

Please see [this helpful article](https://antunderwood.gitlab.io/bioinformant-blog/posts/running_nextflow_on_aws_batch/) on how to configure your AWS environment

# Running

TODO: Figure out how specify this with a github link instead?

## Locally

## Command Template

⚠️ **Warning** Perform this command from the repository root directory

```
./nextflow run main.nf -c "./local_nextflow.config" \
                        --active_channels_path [PATH_TO_ACTIVE_CHANNELS_RDS_FILE] \
                        --channel_bounds_path [PATH_TO_CHANNEL_BOUNDS_RDS_FILE] \
                        --supervised_list_path [PATH_TO_SUPERVISED_LIST_RDS_FILE] \
                        --input_gating_set_directory [PATH_TO_A_DIRECTORY_CONTAINING_FLOW_WORKSPACE_GATING_SET_FILES]
```

## Command Example

⚠️ **Warning** Perform this command from the repository root directory

```
./nextflow run main.nf -c "./local_nextflow.config" \
                        --active_channels_path ~/Desktop/nextflow_testing/helper_files/active_channels.rds \
                        --channel_bounds_path ~/Desktop/nextflow_testing/helper_files/channel_bounds.rds \
                        --supervised_list_path ~/Desktop/nextflow_testing/helper_files/supervised_list.rds \
                        --input_gating_set_directory ~/Desktop/nextflow_testing/dataset
```

## Using AWS Batch

### Command Template

⚠️ **Warning** Perform this command from the repository root directory

```
export AWS_ACCESS_KEY_ID=[REDACTED]
export AWS_SECRET_ACCESS_KEY=[REDACTED]
./nextflow run main.nf -c "./aws_batch_nextflow.config" \
                        --active_channels_path [PATH_TO_ACTIVE_CHANNELS_RDS_FILE] \
                        --channel_bounds_path [PATH_TO_CHANNEL_BOUNDS_RDS_FILE] \
                        --supervised_list_path [PATH_TO_SUPERVISED_LIST_RDS_FILE] \
                        --input_gating_set_directory [PATH_TO_A_DIRECTORY_CONTAINING_FLOW_WORKSPACE_GATING_SET_FILES] \
                        --aws_batch_queue [REDACTED] \
                        -bucket-dir s3://[REDACTED]
```

### Command Example

⚠️ **Warning** Perform this command from the repository root directory

```
export AWS_ACCESS_KEY_ID=[REDACTED]
export AWS_SECRET_ACCESS_KEY=[REDACTED]
./nextflow run main.nf -c "./aws_batch_nextflow.config" \
                        --active_channels_path ~/Desktop/nextflow_testing/helper_files/active_channels.rds \
                        --channel_bounds_path ~/Desktop/nextflow_testing/helper_files/channel_bounds.rds \
                        --supervised_list_path ~/Desktop/nextflow_testing/helper_files/supervised_list.rds \
                        --input_gating_set_directory ~/Desktop/nextflow_testing/dataset \
                        --aws_batch_queue example_queue \
                        -bucket-dir s3://example_bucket
```
