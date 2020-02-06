# Overview

This document covers the process for building the `Nextflow` `Docker` image

# Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

-   [Why Is This Needed](#why-is-this-needed)
-   [Tools](#tools)
-   [Required Environment Variables](#required-environment-variables)
-   [Required Docker Registry Access](#required-docker-registry-access)
-   [Process](#process)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Why Is This Needed

`Nextflow` **requires** a docker image to be specified when running `Nextflow` using `AWS`.

# Tools

| Resource                                                                                             | Resource Type | Description                                                       |
| ---------------------------------------------------------------------------------------------------- | ------------- | ----------------------------------------------------------------- |
| [continuous_integration/build_docker_images.sh](continuous_integration/build_docker_images.sh)       | File          | This script is responsible for building the `Docker` image        |
| [continuous_integration/deploy_docker_images.sh](continuous_integration/deploy_docker_images.sh)     | File          | This script is responsible for deploying the `Docker` image       |
| [continuous_integration/faust_nextflow.dockerfile](continuous_integration/faust_nextflow.dockerfile) | File          | This is the `Dockerfile` that is used to build the `Docker` image |

# Required Environment Variables

| Environment Variable                  | Expected Value                           | Description                                                                                                                                                                            |
| ------------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION` | 0.0.1                                    | This determines the `version` number that the `Docker` image is tagged with, and deployed with. It is important because it will help people target specific implementations of `FAUST` |
| `GITHUB_PAT`                          | 11111111111aaaaaaaaaaa22222222222bbbbbbb | Access to the private `scampDev` repository is required to build the `Docker` image. In order to have access to that a GitHub Personal Access Token (PAT) MUST be provided.            |

# Required Docker Registry Access

In order to `deploy` the `Docker` image that is created you are required to have access to the repository being published to.

The current repository being published to is [RGLab on DockerHub](https://hub.docker.com/orgs/rglab). Please make sure you have access to this.

# Process

⚠️ **Warning** Perform these commands from the repository's `root directory`

1. Clone the repository
1. In a terminal navigate to the `root directory` of the repository
1. Set the required environment variables
    - `export FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION="0.0.1"`
        - Ideally, this should match the version of `FAUST` being used
    - `export GITHUB_PAT="11111111111aaaaaaaaaaa22222222222bbbbbbb"`
1. Build the `Docker` image
    - `sh continuous_integration/build_docker_images.sh`
1. Deploy the `Docker` image
    - `sh continuous_integration/deploy_docker_images.sh`

After that the docker image should be available to use!
