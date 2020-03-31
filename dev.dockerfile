# docker build -t ericsgagnon/dev:dev -f ./dev.dockerfile .
# code-server with more up to date versions of languages:

#ARG BASE_OS=buster
ARG BASE_OS=bionic
ARG GOLANG_VERSION=1.14
ARG RUST_VERSION=1.42
ARG R_VERSION=3.6.2
ARG PYTHON_VERSION=3.8
#ARG PYTHON_PIP_VERSION=19.2.1 # shouldn't need to set this explicitly
ARG OIC_VERSION=19.3
ARG CODE_SERVER_VERSION=3.0.1

FROM golang:${GOLANG_VERSION}       as golang
FROM rocker/geospatial:${R_VERSION} as rlang
FROM rust:${RUST_VERSION}           as rustlang
FROM python:${PYTHON_VERSION}       as python

#  ########################################################
FROM buildpack-deps:${BASE_OS}

ARG BASE_OS
ARG GOLANG_VERSION
ARG RUST_VERSION
ARG R_VERSION
ARG PYTHON_VERSION
#ARG PYTHON_PIP_VERSION=19.2.1 # shouldn't need to set this explicitly
ARG OIC_VERSION
ARG CODE_SERVER_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
ENV LANG=en_US.UTF-8

# go ########################################################
COPY --from=golang  /usr/local/go /usr/local/go
COPY --from=golang  /go           /go
COPY --from=golang  /go           /etc/go

ENV GOLANG_VERSION=${GOLANG_VERSION}
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN apt update && apt install -y \
  python${PYTHON_VERSION} \
  python${PYTHON_VERSION}-dev \
  python${PYTHON_VERSION}-dbg \
  python${PYTHON_VERSION}-venv \
  libpython${PYTHON_VERSION} \
  libpython${PYTHON_VERSION}-dev \
  libpython${PYTHON_VERSION}-dbg \
  libpython${PYTHON_VERSION}-stdlib \
  libpython${PYTHON_VERSION}-testsuite \
  idle-python${PYTHON_VERSION} \
  python3-pip

#  libpython${PYTHON_VERSION}-venv \

RUN echo $PYTHON_VERSION $GOLANG_VERSION ${GOLANG_VERSION}

RUN apt update && apt install -y \
		libbluetooth-dev \
		tk-dev \
		uuid-dev \
	  && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
    liblwgeom-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev

