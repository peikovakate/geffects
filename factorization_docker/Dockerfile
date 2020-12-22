FROM nfcore/base:1.9

LABEL authors="Kateryna Peikova" \
    description="Docker image containing all software requirements for the nf-core/geffects matrix factorization pipeline"

# Install the conda environment
COPY environment.yml /
RUN conda env create -f /environment.yml

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /opt/conda/envs/nf-core-geffects-1.0dev/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nf-core-geffects-1.0dev > nf-core-geffects-1.0dev.yml
