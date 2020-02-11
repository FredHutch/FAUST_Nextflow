FROM r-base:3.6.1

# Configure the environment to use the configured personal access token with GitHub
# Errors out if the argument is not available
ARG CI_GITHUB_PAT
RUN test -n "$CI_GITHUB_PAT" || (echo "CI_GITHUB_PAT  not set and is required to build the docker image" && false)
ENV GITHUB_PAT=${CI_GITHUB_PAT}

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
# Install `devtools`
RUN R -e "install.packages('devtools', repos='https://cloud.r-project.org/', version='2.2.1')"

# Install `FAUST` dependencies
# Install BiocManager
RUN R -e "install.packages(c('BiocManager'), repos='https://cloud.r-project.org/', version='1.30.10')"
RUN R -e "BiocManager::install('Biobase', version='3.10')"
RUN R -e "devtools::install_github('RGLab/RProtoBufLib',ref='trunk')"
#RUN R -e "BiocManager::install('RProtoBufLib', version='devel')"
RUN R -e "devtools::install_github('RGLab/cytolib',ref='master')"
#RUN R -e "BiocManager::install('cytolib', version='3.10')"
RUN R -e "devtools::install_github('RGLab/flowCore',ref='master')"
#RUN R -e "BiocManager::install('flowCore', version='3.10')"
RUN R -e "devtools::install_github('RGLab/ncdfFlow',ref='trunk')"
#RUN R -e "BiocManager::install('ncdfFlow', version='3.10')"
RUN R -e "devtools::install_github('RGLab/flowWorkspace',ref='master')"
#RUN R -e "BiocManager::install('flowWorkspace', version='3.10')"
RUN R -e "devtools::install_github('RGLab/ggcyto',ref='master')"
#RUN R -e "BiocManager::install('ggcyto', version='3.10')"

# Set dev tools installation to use GitHub personal access token that was passed in
RUN R -e "usethis::browse_github_pat()"

RUN R -e "devtools::install_github('FredHutch/scampDev', auth_token='$GITHUB_PAT')"
RUN R -e "install.packages('cowplot', repos='https://cloud.r-project.org/', version='1.0.0')"
RUN R -e "install.packages('viridis', repos='https://cloud.r-project.org/', version='0.5.1')"
RUN R -e "install.packages('tidyr', repos='https://cloud.r-project.org/', version='1.0.0')"
RUN R -e "install.packages('ggridges', repos='https://cloud.r-project.org/', version='0.5.1')"

COPY faust_r_lib faust
RUN R CMD INSTALL faust  --preclean
