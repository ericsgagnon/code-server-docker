# docker build -t ericsgagnon/code-server:ls -f linuxserver.dockerfile .
# docker run -dit --name xls ericsgagnon/code-server:ls 
# docker exec -i -t xls /bin/bash 
# docker rm -fv xls
#docker run -dit --name=ls -e PUID=1000 -e PGID=1000 -e TZ=America/New_York -e PASSWORD=password -e SUDO_PASSWORD=password -p 8557:8443 linuxserver/code-server:3.0.1-ls22

#  ########################################################

#ARG BASE_OS=bionic
ARG GOLANG_VERSION=1.14
ARG RUST_VERSION=1.42
ARG R_VERSION=3.6.2
ARG PYTHON_VERSION=3.8
ARG OIC_VERSION=19.6
ARG CODE_SERVER_VERSION=3.0.1

FROM golang:${GOLANG_VERSION}       as golang
FROM rocker/geospatial:${R_VERSION} as rlang
FROM rust:${RUST_VERSION}           as rustlang
FROM python:${PYTHON_VERSION}       as python

# Image ###################################################
#FROM linuxserver/code-server:3.0.1-ls22
FROM buildpack-deps:bionic

ARG GOLANG_VERSION
ARG RUST_VERSION
ARG R_VERSION
ARG PYTHON_VERSION
ARG OIC_VERSION
ARG CODE_SERVER_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
#ENV LANGUAGE
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV PASSWORD password

RUN apt update -y && apt upgrade -y && \
    apt install -y --no-install-recommends \
    aptitude \
    man

# R #######################################################
ENV R_VERSION=${R_VERSION}

COPY --from=rlang /opt/TinyTeX/    /opt/TinyTeX/
COPY --from=rlang /usr/local/lib/  /usr/local/lib/
COPY --from=rlang /usr/local/bin/  /usr/local/bin/

RUN ldconfig

# python ##################################################

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN apt update -y && apt upgrade -y && \
    apt install -y --no-install-recommends \
    aptitude \
    man

COPY --from=python /usr/local/lib/  /usr/local/lib/
COPY --from=python /usr/local/bin/  /usr/local/bin/

RUN ldconfig

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    jq \
    libblas-dev \
    libbz2-1.0 \
    libcurl4 \
    libicu-dev \
    libicu60 \
    libjpeg-turbo-progs \
    libjpeg-turbo-test \
    libjpeg-turbo8 \
    libjpeg-turbo8-dbg \
    libjpeg-turbo8-dev \
    libturbojpeg \
    libturbojpeg0-dev \
    libopenblas-dev \
    libpangocairo-1.0-0 \
    libpcre3 \
    libpng16-16 \
    libreadline7 \
    libtiff5 \
    liblzma5 \
    locales \
    make \
    python3-software-properties \
    software-properties-common \
    unzip \
    zip \
    zlib1g

