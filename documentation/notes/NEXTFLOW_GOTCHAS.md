# Process

## Process.workDir vs Docker Working Directory

A job definition for AWS Batch requires configuring the volume attachment so that the working directory being used has the correct amount of space to run the job in while processing

This is NOT the same os the `process.workDir`

Per `Sam Minot`

> The `process.workDir` is the S3 bucket used to store intermediate files and pass them between processes

# AWS Batch

## Auto Creation of Job Definitions

A job definition is required in order to configure the environment for execution on the AWS Instance

You can manually declare a job definition or let Nextflow handle that for you by appending `:/tmp:rw` to the volume being used for processing

```
aws {
    region = "$params.aws_region"
    batch {
        cliPath = "/home/ec2-user/miniconda/bin/aws"
        volumes = ['/docker_scratch:/tmp:rw']
    }
}
```

volumes = ['/docker_scratch:/tmp:rw']
