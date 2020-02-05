regarding your question about "Dynamic Computing Resources":

I think the problem is that in your case, NF doesn't handle the retry by itself but delegates it to AWS Batch. If you check your logs in the AWS Batch Dashboard you might see that some jobs have been executed 3 times in a row within AWS Batch (so, NF submits a job once but AWS executes it 3 times).

If I am not mistaken, this behaviour is related to this code: https://github.com/nextflow-io/nextflow/blob/92534be780f77c8cf0834c1b0bcc3b444ce9cf67/modules/nextflow/src/main/groovy/nextflow/cloud/aws/batch/AwsBatchTaskHandler.groovy#L517

I assume the problem is caused by errorStrategy = {task.exitStatus in [137, 138, 139, 140, 141, 142, 143] ? 'retry' : 'finish'}. When a process is executed the first time, task.exitStatus is not set and consequently, errorStrategy is not retry. However, as stated in the NF code linked above, only if errorStrategy == 'retry', the retries are performed by NF itself, and consequently, only then the resources are increased in the 2nd and 3rd run. So, specifying errorStrategy = { task.attempt < =3 ? 'retry' : 'finish' } should work. And if you want to specify the exit status something like this might work (however I didn't test it):
errorStrategy = { task.attempt == 1 || task.exitStatus in [137, 138, 139, 140, 141, 142, 143] ? 'retry' : 'finish'}

Hope that helps
