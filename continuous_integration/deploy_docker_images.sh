if [[ -z "${FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION}" ]]; then
    echo "'FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION' environment variable was NOT detected!"
    echo "In order to build the docker image, the 'FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION' environment variable MUST declared in the form 'x.y.z'"
    exit 1
fi
docker push rglab/faust-nextflow:$FAUST_NEXTFLOW_DOCKER_IMAGE_VERSION