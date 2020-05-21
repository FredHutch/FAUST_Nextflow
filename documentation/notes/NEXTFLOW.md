<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

-   [AWS Batch Reading](#aws-batch-reading)
-   [Text Editor Integration](#text-editor-integration)
    -   [Sublime Text](#sublime-text)
-   [Idiomatic Usage](#idiomatic-usage)
-   [Inspiration](#inspiration)
-   [Scaling](#scaling)
-   [Printing Output in Workflows/Groovy](#printing-output-in-workflowsgroovy)
-   [Printing Output a Process](#printing-output-a-process)
-   [Repeating a Channel's Inputs](#repeating-a-channels-inputs)
-   [Random](#random)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# AWS Batch Reading

-   https://www.nextflow.io/blog/2017/scaling-with-aws-batch.html
    -   From the horses mouth

# Text Editor Integration

## Sublime Text

-   https://github.com/peterk87/sublime-nextflow
    -   How to Install: https://github.com/peterk87/sublime-nextflow/issues/2

# Idiomatic Usage

-   https://github.com/nextflow-io/patterns

# Inspiration

-   https://github.com/nextflow-io/awesome-nextflow/
-   https://github.com/stevekm/nextflow-demos

# Scaling

-   Dynamic Computing Resources
    -   https://www.nextflow.io/docs/latest/process.html?dynamic-computing-resources#dynamic-computing-resources
-   Auto-retry Scaling Examples
    -   https://nf-co.re/sarek/docs/usage#automatic-resubmission
    -   See here: https://github.com/nf-core/sarek/blob/master/conf/base.config

# Printing Output in Workflows/Groovy

You need to use `-ansi-log false` in the command to run nextflowu

```
./nextflow run main.nf -c "./local_nextflow.config" \
                       -ansi-log false
```

Then just `print` in the workflow
`println` also works

```
print example_variable
```

# Printing Output a Process

Use the `echo true` directive

See: https://www.nextflow.io/docs/latest/process.html#echo

# Repeating a Channel's Inputs

```groovy
Channel.from([1, 2]\*3).view()
1
2
1
2
1
2
```

# Random

-   https://github.com/csiro-crop-informatics/nextflow-embl-abr-webinar/blob/master/nextflow-tutorial.md#cloud-profile
-   https://antunderwood.gitlab.io/bioinformant-blog/posts/running_nextflow_on_aws_batch/
