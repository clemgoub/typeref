# Set the base image to debian jessie
FROM debian:jessie

# File Author / Maintainer
MAINTAINER Clement Goubert <goubert.clement@gmail.com>

# install base programs
RUN apt-get update && apt-get install --yes --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    locales \
    vim-tiny \
    nano \
    git \
    make \
    cmake \
    build-essential \
    gcc-multilib \
    perl \
    bioperl \
    cpanminus \
    expat \
    libexpat1-dev \
    python \
    parallel \
    tabix \
    vcftools \
    bwa \
    libbz2-dev \
    libcurl4-gnutls-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    liblzma-dev


# install miniconda
# ENV PATH="/root/miniconda2/bin:${PATH}"
# ARG PATH="/root/miniconda2/bin:${PATH}"
# RUN wget \
#    https://repo.anaconda.com/miniconda/Miniconda2-latest-Linux-x86_64.sh \
#    && bash Miniconda2-latest-Linux-x86_64.sh -b

# install bedtools 2.29.1 (bedtools must be this version for compatibility)
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.30.0/bedtools.static.binary \
&& mv bedtools.static.binary bedtools \
&& chmod a+x bedtools \
&& mv bedtools /usr/bin/

# install perl modules
RUN cpanm --force XML::Parser \
	XML::DOM \
	XML::Twig \
	String::Approx \
	List::MoreUtils

# Update/Upgrade pip and install pysam
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py \
&&  python get-pip.py \
&&  pip install pysam

# install htslib

RUN cd /usr/bin \
&&  wget https://github.com/samtools/htslib/releases/download/1.10.2/htslib-1.10.2.tar.bz2 \
&&  tar -vxjf htslib-1.10.2.tar.bz2 \
&&  cd htslib-1.10.2 \
&&  make

# install samtools
RUN cd /usr/bin \
&&  wget https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2 \
&&  tar -vxjf samtools-1.10.tar.bz2 \
&&  cd samtools-1.10 \
&&  make

# install pysam
# RUN ~/miniconda2/bin/conda config --add channels r \
# &&  ~/miniconda2/bin/conda config --add channels bioconda \
# &&  ~/miniconda2/bin/conda install pysam

#Export paths
ENV PATH=/usr/bin/samtools-1.10:$PATH
ENV PATH=/usr/bin/htslib-1.10.2:$PATH
