# Set the base image to debian jessie
FROM debian:jessie

# File Author / Maintainer
MAINTAINER Clement Goubert <goubert.clement@gmail.com>

# install base programs
RUN apt-get update && apt-get install --yes --no-install-recommends \
    wget \
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
    python-pysam \
    libbz2-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    liblzma-dev

# install bedtools 2.29.1 (bedtools must be this version for compatibility)
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.30.0/bedtools.static.binary \
&& mv bedtools.static.binary bedtools \
&& chmod a+x bedtools \
&& mv bedtools /usr/bin/

#Install perl modules
RUN cpanm --force XML::Parser \
	XML::DOM \
	XML::Twig \
	String::Approx \
	List::MoreUtils

#Install htslib

RUN cd /usr/bin \
&&  wget https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 \
&&  tar -vxjf htslib-1.9.tar.bz2 \
&&  cd htslib-1.9 \
&&  make

#Install samtools
RUN cd /usr/bin \
&&  wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 \
&&  tar -vxjf samtools-1.9.tar.bz2 \
&&  cd samtools-1.9 \
&&  make

#Export paths
ENV PATH=/usr/bin/samtools-1.9:$PATH
ENV PATH=/usr/bin/htslib-1.9:$PATH
