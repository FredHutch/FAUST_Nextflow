FAUST_NEXTFLOW_IMAGE_VERSION=0.0.1
docker build --file continuous_integration/faust.dockerfile \
             --build-arg CI_GITHUB_PAT=$GITHUB_PERSONAL_ACCESS_TOKEN \
             --tag rglab/faust-nextflow:$FAUST_NEXTFLOW_IMAGE_VERSION \
             .
