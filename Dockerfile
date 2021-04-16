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
    samtools \
    bwa \
    python-pysam

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

#Install insertion-genotype
RUN git clone https://github.com/KiddLab/insertion-genotype.git