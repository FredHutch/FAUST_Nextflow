# Configure Environment

## OSX

-   Install Python 3
    -   `brew install python`
-   Install `virtualenv` to create the environment
    -   See: https://virtualenv.pypa.io/en/latest/installation.html
    -   `python -m pip install --user venv`

# Run

Please follow the steps in `Configure Environment` first
Make sure you are in the `tests` directory when running these commands

-   `cd tests`
-   Create `virtualenv`
    -   `virtualenv venv`
-   Activate `virtualenv`
    -   `source venv/bin/activate`
-   Install test dependencies
    -   `pip install -r test_requirements.txt`
-   Create the required environment variables
    -   `export AWS_ACCESS_KEY_ID=[REDACTED]`
    -   `export AWS_SECRET_ACCESS_KEY=[REDACTED]`
    -   `export FAUST_NEXTFLOW_TESTING_BATCH_PROCESS_QUEUE_NAME="[REDACTED]"`
    -   `export FAUST_NEXTFLOW_TESTING_AMAZON_S3_BUCKET_NAME="[REDACTED]"`
    -   `export FAUST_NEXTFLOW_TESTING_AMAZON_S3_VALID_LEGACY_GATING_SETS_DIRECTORY_PATH="[REDACTED]"`
    -   `export FAUST_NEXTFLOW_TESTING_AMAZON_S3_VALID_GATING_SETS_DIRECTORY_PATH="[REDACTED]"`
-   `pytest test_faust_nextflow.py`
-   Check `FAUST_NEXTFLOW_TESTING_LOG.log` to see all output
