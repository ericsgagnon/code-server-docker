# docker build -t code-server:dev .
# multi-stage code server for go, python, javascript development

FROM golang:1.12.6-stretch as golang

FROM python:3.7.3-stretch as python

FROM codercom/code-server:latest as code-server

USER root

# setup go
ENV GOLANG_VERSION 1.12.6
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=golang /usr/local/go /usr/local/go

#WORKDIR $GOPATH

#USER root

# setup python
ENV PATH /usr/local/bin:$PATH
ENV PYTHON_VERSION 3.7.3
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8
ENV PYTHON_PIP_VERSION 19.1.1
ENV TZ UTC
ENV DEBIAN_FRONTEND noninteractive

# extra dependencies (over what buildpack-deps already includes)
RUN apt-get update && apt-get install -y --no-install-recommends \
		apt-utils \
		tzdata \
		uuid-dev \
	&& rm -rf /var/lib/apt/lists/*
#		tk-dev \

COPY --from=python /usr/local/bin/idle3 /usr/local/bin/idle3
COPY --from=python /usr/local/bin/pydoc3 /usr/local/bin/pydoc3
COPY --from=python /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python /usr/local/bin/python3-config /usr/local/bin/python3-config

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config
