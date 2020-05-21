FROM r-base:4.0.0

# Configure the environment to use the configured personal access token with GitHub
# Errors out if the argument is not available
ARG SCAMP_VERSION="v0.5.0"
ARG FAUST_VERSION="v0.5.0"
ARG BIOCONDUCTOR_VERSION="3.11"

# Install R `devtools` external dependencies
# autoconf - required for R Protobuf
# procps - required for metric generation in Nextflow, not required for FAUST
RUN apt-get update \
    && apt-get install --yes autoconf \
                             libcurl4-openssl-dev \
                             libssl-dev \
                             libxml2-dev \
                             procps \
                             python3.7 \
                             python3-pip \
                             python3-setuptools \
                             python3-dev


# Install `devtools` R dependencies
RUN R -e "install.packages('curl', repos='https://cloud.r-project.org/', version='4.3')"
RUN R -e "install.packages('xml2', repos='https://cloud.r-project.org/', version='1.2.2')"
RUN R -e "install.packages('fdrtool', repos='https://cloud.r-project.org/', version='1.2.15')"
# Install `devtools`
RUN R -e "install.packages('devtools', repos='https://cloud.r-project.org/', version='2.2.1')"

# Install `FAUST` dependencies
# Install BiocManager
RUN R -e "install.packages(c('BiocManager'), repos='https://cloud.r-project.org/', version='1.30.10')"

RUN R -e "BiocManager::install('Biobase', update = FALSE, version = '$BIOCONDUCTOR_VERSION')"
RUN R -e "BiocManager::install('RProtoBufLib', update = FALSE, version = '$BIOCONDUCTOR_VERSION')"
RUN R -e "BiocManager::install('cytolib', update = FALSE, version = '$BIOCONDUCTOR_VERSION')"
RUN R -e "BiocManager::install('flowCore', update = FALSE, version = '$BIOCONDUCTOR_VERSION')"
RUN R -e "BiocManager::install('ncdfFlow', update = FALSE, version = '$BIOCONDUCTOR_VERSION')"
RUN R -e "BiocManager::install('flowWorkspace', update = FALSE, version = '$BIOCONDUCTOR_VERSION')"
RUN R -e "BiocManager::install('ggcyto', update = FALSE, version = '$BIOCONDUCTOR_VERSION')"

RUN R -e "devtools::install_github('RGLab/scamp', ref='$SCAMP_VERSION')"
RUN R -e "devtools::install_github('RGLab/FAUST', ref='$FAUST_VERSION')"
