<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Template Candidates](#template-candidates)
  - [Breakdown of Resources](#breakdown-of-resources)
  - [AWS Specific](#aws-specific)
  - [Alternate](#alternate)
- [Required Architecture](#required-architecture)
  - [Required Settings to Run Nextflow](#required-settings-to-run-nextflow)
  - [AMI](#ami)
  - [User](#user)
  - [Batch](#batch)
  - [Job Queue](#job-queue)
  - [Compute Environment](#compute-environment)
- [S3](#s3)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Template Candidates

## Breakdown of Resources

-   https://aws.amazon.com/blogs/compute/building-high-throughput-genomic-batch-workflows-on-aws-batch-layer-part-3-of-4/

## AWS Specific

-   https://aws.amazon.com/quickstart/biotech-blueprint/nextflow/

## Alternate

-   https://docs.opendata.aws/genomics-workflows/quick-start/
    -   Raw version for Nextflow here
        -   https://github.com/aws-samples/aws-genomics-workflows/blob/master/src/templates/nextflow/nextflow-resources.template.yaml

# Required Architecture

## Required Settings to Run Nextflow

-   AWS_ACCESS_KEY_ID
-   AWS_SECRET_ACCESS_KEY
-   AWS_DEFAULT_REGION

## AMI

Needs to be configued with explicit paths

-   Valid AMI with correctly configured cli paths
    -   TODO: Not sure both parameters are needed?
    -   `aws.batch.cliPath = "/home/ec2-user/miniconda/bin/aws"`
    -   `executor.awscli = "/home/ec2-user/miniconda/bin/aws"`

## User

-   Nextflow Service Account
-   Lock down permissions, only allow correct access for necessary resources

## Batch

TODO

## Job Queue

-   Compute Environment

## Compute Environment

-   Instance Role
-   Service Role
-   EC2 Key Pair?

# S3

-   A Single bucket
