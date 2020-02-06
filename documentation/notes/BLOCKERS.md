<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AWS CloudFormation](#aws-cloudformation)
  - [S3 Bucket](#s3-bucket)
    - [Stack Delete - Deleting an S3 bucket](#stack-delete---deleting-an-s3-bucket)
      - [Workarounds](#workarounds)
  - [Compute Environment](#compute-environment)
    - [Public AMI image is required](#public-ami-image-is-required)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# AWS CloudFormation

## S3 Bucket

### Stack Delete - Deleting an S3 bucket

This is not possible if it has data

#### Workarounds

"DeletionPolicy" : "Retain"

## Compute Environment

### Public AMI image is required

Current public image is: `ami-0a9d84df942521898`

Had to create an ami with attached EBS of 1TB

