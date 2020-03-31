# docker build -t ericsgagnon/code-server:trash -f ./trash.dockerfile .
# code-server with more up to date versions of languages:

#ARG BASE_OS=bionic
ARG GOLANG_VERSION=1.14
ARG RUST_VERSION=1.42
ARG R_VERSION=3.6.2
ARG PYTHON_VERSION=3.8
ARG OIC_VERSION=19.6
ARG CODE_SERVER_VERSION=3.0.1

FROM golang:${GOLANG_VERSION}       as golang
#FROM rocker/geospatial:${R_VERSION} as rlang
FROM ericsgagnon/rstudio:v${R_VERSION} as rlang
FROM rust:${RUST_VERSION}           as rustlang
FROM python:${PYTHON_VERSION}       as python


FROM ericsgagnon/rstudio:v${R_VERSION}

ARG GOLANG_VERSION
ARG RUST_VERSION
ARG R_VERSION
ARG PYTHON_VERSION
ARG OIC_VERSION
ARG CODE_SERVER_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
ENV LANG=en_US.UTF-8
ENV PASSWORD password

RUN apt update -y && apt upgrade -y && \
    apt install -y --no-install-recommends \
    aptitude \
    man

COPY --from=python /usr/local/lib/  /usr/local/lib/
COPY --from=python /usr/local/bin/  /usr/local/bin/

RUN ldconfig
############################################################################################################


#https://marketplace.visualstudio.com/_apis/public/gallery/publishers/stkb/vsextensions/rewrap/1.9.1/vspackage
#https://marketplace.visualstudio.com/_apis/public/gallery/publishers/
#stkb/
#vsextensions/rewrap/1.9.1/vspackage