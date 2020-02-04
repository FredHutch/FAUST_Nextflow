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

