FROM r-base:3.6.1

# Install R `devtools` external dependencies
RUN apt-get update \
    && apt-get install --yes libcurl4-openssl-dev \
                             libssl-dev \
                             libxml2-dev \
                             python3.7 \
                             python3-pip \
                             python3-setuptools \
                             python3-dev

# Install `configr` to support user configurations for FAUST
RUN R -e "install.packages('configr', repos='https://cloud.r-project.org/')"

# Install `devtools` R dependencies
RUN R -e "install.packages('curl', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('xml2', repos='https://cloud.r-project.org/')"
# Install `devtools`
RUN R -e "install.packages('devtools', repos='https://cloud.r-project.org/')"

# Install `FAUST` dependencies
# Install BiocManager
RUN R -e "install.packages(c('BiocManager'), repos='https://cloud.r-project.org/')"
RUN R -e "BiocManager::install('Biobase', update = FALSE)"
RUN R -e "BiocManager::install('flowWorkspaceData', update = FALSE)"

# Install Required FAUST dependencies
ARG GITHUB_PAT
RUN R -e "usethis::browse_github_pat()"
RUN R -e "devtools::install_github('RGLab/RProtoBufLib', ref='trunk')"
RUN R -e "devtools::install_github('RGLab/cytolib', ref='trunk')"
RUN R -e "devtools::install_github('RGLab/flowCore', ref='trunk')"
RUN R -e "devtools::install_github('RGLab/ncdfFlow', ref='trunk')"
RUN R -e "devtools::install_github('RGLab/flowWorkspace', ref='trunk')"
RUN R -e "devtools::install_github('RGLab/ggcyto', ref='trunk')"

RUN R -e "devtools::install_github('FredHutch/scampDev', auth_token='$GITHUB_PAT')"
RUN R -e "install.packages(c('cowplot', 'viridis', 'tidyr', 'ggridges'))"
COPY faust_r_lib faust
RUN R CMD INSTALL faust  --preclean
