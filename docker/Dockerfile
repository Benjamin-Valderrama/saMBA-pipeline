FROM rocker/r-base:4.3.3

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libxslt1-dev \
    wget \
    git \
    bzip2 \
    procps \
    htop \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p $CONDA_DIR && \
    rm miniconda.sh
ENV PATH=$CONDA_DIR/bin:$PATH

# Configure Conda channels
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge

# Create a Conda env with Python 3.10 and install fastq-dl 3.0.0
RUN conda create -y -n sambaenv python=3.10 fastq-dl=3.0.0 && \
    echo "source activate sambaenv" >> ~/.bashrc
ENV PATH /opt/conda/envs/sambaenv/bin:$PATH

# Install dada2 and tidyverse in R
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org'); \
          BiocManager::install('dada2', update = FALSE, ask = FALSE); \
          install.packages('tidyverse', repos='https://cloud.r-project.org')"

# Clone the GitHub repository
RUN git clone https://github.com/Benjamin-Valderrama/saMBA-pipeline

# Default to interactive bash shell
CMD ["/bin/bash"]
