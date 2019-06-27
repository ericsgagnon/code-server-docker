# docker build -t ericsgagnon/code-server:dev .
# code-server with more up to date versions of languages:
# go 1.12.6
# python 3.7.3

ARG GOLANG_VERSION=1.12.6

#FROM golang:1.12.6-stretch as golang
FROM golang:${GOLANG_VERSION}-stretch as golang

ARG   OIC_VERSION=19.3

# Oracle Instant Client (oci) ########################################################################
#
# https://github.com/oracle/docker-images/blob/master/OracleInstantClient/dockerfiles/18.3.0/Dockerfile

FROM oraclelinux:7-slim as oracle-instant-client

ARG  OIC_VERSION


RUN  curl -o /etc/yum.repos.d/public-yum-ol7.repo https://yum.oracle.com/public-yum-ol7.repo && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient$OIC_VERSION-basic oracle-instantclient$OIC_VERSION-devel oracle-instantclient$OIC_VERSION-sqlplus && \
     rm -rf /var/cache/yum


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

# python
# https://github.com/docker-library/python/blob/34c9df35e9a69e9f0edde88e861b543edb8bc07a/3.7/stretch/Dockerfile
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

#FROM buildpack-deps:stretch

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8
ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.7.3
ENV TZ UTC
ENV DEBIAN_FRONTEND noninteractive

# extra dependencies (over what buildpack-deps already includes)
RUN apt-get update && apt-get install -y --no-install-recommends \
		tk-dev \
		uuid-dev \
	&& rm -rf /var/lib/apt/lists/*


RUN set -ex \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	&& make -j "$(nproc)" \
	&& make install \
	&& ldconfig \
	\
	&& find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	\
	&& python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.1.1

RUN set -ex; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

#CMD ["python3"]