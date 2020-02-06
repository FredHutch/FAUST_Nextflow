if [[ -z "${FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION}" ]]; then
    echo "'FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION' environment variable was NOT detected!"
    echo "In order to build the docker image, the 'FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION' environment variable MUST declared in the form 'x.y.z'"
    exit 1
fi
if [[ -z "${GITHUB_PAT}" ]]; then
    echo "'GITHUB_PAT' environment variable was NOT detected!"
    echo "In order to build the docker image, the 'GITHUB_PAT' environment variable MUST declared in the form 'xxxxxxxxxyyyyyyyyyyzzzzzzz'"
    exit 1
fi

docker build --file continuous_integration/faust_nextflow.dockerfile \
             --build-arg CI_GITHUB_PAT=$GITHUB_PAT \
             --tag rglab/faust-nextflow:$FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION \
             .
