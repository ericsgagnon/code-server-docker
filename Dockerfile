# docker build -t ericsgagnon/code-server:dev .
# code-server with more up to date versions of languages:
# go 1.12.7
# python 3.7.4

ARG GOLANG_VERSION=1.12.7
ARG PYTHON_VERSION=3.7.4
#ARG PYTHON_PIP_VERSION=19.2.1 # shouldn't need to set this explicitly
ARG OIC_VERSION=19.3
ARG CODE_SERVER_VERSION=1.1156-vsc1.33.1

FROM golang:${GOLANG_VERSION} as golang

FROM codercom/code-server:${CODE_SERVER_VERSION} as code-server

# Oracle Instant Client (oci) ########################################################################
#
# https://github.com/oracle/docker-images/blob/master/OracleInstantClient/dockerfiles/18.3.0/Dockerfile

FROM oraclelinux:7-slim as oracle-instant-client

ARG OIC_VERSION
ENV OIC_VERSION ${OIC_VERSION}

RUN  curl -o /etc/yum.repos.d/public-yum-ol7.repo https://yum.oracle.com/public-yum-ol7.repo && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install \
	 oracle-instantclient$OIC_VERSION-basic \
	 oracle-instantclient$OIC_VERSION-devel \
	 oracle-instantclient$OIC_VERSION-sqlplus && \
     rm -rf /var/cache/yum

# Final Stage ###########################################################################################
# using python base image for convenience - it has the most complicated install process...
FROM python:${PYTHON_VERSION} as final

ARG OIC_VERSION
ENV OIC_VERSION ${OIC_VERSION}
ENV TZ UTC
ENV DEBIAN_FRONTEND noninteractive

USER root

# Go ##################################################

# setup go
ARG GOLANG_VERSION
ENV GOLANG_VERSION ${GOLANG_VERSION}
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

# DB Drivers ##########################################

# Oracle drivers are super-special
ENV  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/oracle/$OIC_VERSION/client64/lib:/usr/include/oracle/$OIC_VERSION/client64/
ENV  OCI_LIB=/usr/lib/oracle/$OIC_VERSION/client64/lib
ENV  OCI_INC=/usr/include/oracle/$OIC_VERSION/client64

COPY --from=oracle-instant-client  /usr/lib/oracle /usr/lib/oracle
COPY --from=oracle-instant-client  /usr/share/oracle /usr/share/oracle
COPY --from=oracle-instant-client  /usr/include/oracle /usr/include/oracle
COPY ./oci8.pc /usr/lib/pkgconfig/oci8.pc

RUN  sed -i 's/OIC_VERSION/'"$OIC_VERSION"'/' /usr/lib/pkgconfig/oci8.pc && \
     apt update && apt install -y \
     libaio1 \
     unixodbc \
     unixodbc-dev \
     tdsodbc \
     odbc-postgresql \
     libsqliteodbc \
     mariadb-client \
     curl \
     net-tools

# Code-Server #########################################
ARG CODE_SERVER_VERSION
ENV CODE_SERVER_VERSION ${CODE_SERVER_VERSION}

COPY --from=code-server /usr/local/bin/code-server /usr/local/bin/code-server

# setup codercom/code-server
RUN apt-get update && apt-get install -y \
	openssl \
	git \
	locales \
	sudo \
	dumb-init \
	vim \
	curl \
	wget \
	nano

RUN locale-gen en_US.UTF-8
# We unfortunately cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
# ENV LC_ALL=en_US.UTF-8

RUN adduser --gecos '' --disabled-password coder && \
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER coder

# We create first instead of just using WORKDIR as when WORKDIR creates, the user is root.
RUN mkdir -p /home/coder/project

WORKDIR /home/coder/project
USER root
# This assures we have a volume mounted even if the user forgot to do bind mount.
# So that they do not lose their data if they delete the container.
VOLUME [ "/home/coder/project" ]

EXPOSE 8443

ENTRYPOINT ["dumb-init", "code-server"]
