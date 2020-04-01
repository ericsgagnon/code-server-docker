# docker build -t ericsgagnon/code-server:3.0.1 -f ./Dockerfile .
# docker run -dit --name code-server -p 9101:8080 ericsgagnon/code-server:3.0.1
# docker logs code-server
# docker rm -fv code-server

# Description: ##################################################
# code-server with as many up-to-date, pre-installed tools as I 
# can manage. Note that, due to the extreme PITA of installing R
# packages on linux (all compiled by source...), the image uses 
# an image derived from rocker/geospatial as its base. If I 
# have time (or if I can find a cran mirror for linux that serves 
# binaries), I may eventually swap this to pure buildpack-deps.
# ###############################################################

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

# Image ############################################################
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

# go ######################################################
ARG GOLANG_VERSION=1.14.1

ENV GOLANG_VERSION=${GOLANG_VERSION}
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

COPY --from=golang  /usr/local/go /usr/local/go
COPY --from=golang  /go           /go

RUN apt-get update && apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config && \
    chmod -R 777 "$GOPATH" && \
    chsh -s /bin/bash

ENV SHELL=/bin/bash


# rust ####################################################

ARG RUST_VERSION
ENV RUST_VERSION=${RUST_VERSION}

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

COPY --from=rustlang  /usr/local/rustup /usr/local/rustup
COPY --from=rustlang  /usr/local/cargo /usr/local/cargo


# bazel ###################################################

RUN curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add - && \
    echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" >> /etc/apt/sources.list.d/bazel.list && \
    apt update && apt install -y \
    bazel

# kubectl #################################################

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list && \
    apt update && apt install -y \
    kubeadm \
    kubectl

# helm ####################################################

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

# docker cli ##############################################

RUN apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - && \
    apt install -y software-properties-common && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt update && apt install -y \
    docker-ce-cli

# code-server #############################################

ENV CODE_SERVER_VERSION=${CODE_SERVER_VERSION}

RUN apt update && apt install -y --no-install-recommends \
    sudo \
    dumb-init \
    htop \
    jq \
    locales \
    man \
    nano \
    procps \
    ssh \
    vim

RUN echo "alias ll='ls -alh '" >> /etc/skel/.bashrc && \
    echo "source <(kubectl completion bash)" >> /etc/skel/.bashrc && \
    echo "source <(helm completion bash)" >> /etc/skel/.bashrc && \
    sed -i -r 's/^(export PATH.*)/\1:$PATH/g' /etc/skel/.bashrc && \
    deluser --remove-home rstudio && \
    adduser --gecos '' --disabled-password coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

RUN cd /tmp && \
    wget https://github.com/cdr/code-server/releases/download/${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf code-server*.tar.gz && rm code-server*.tar.gz && \
    mv code-server* /usr/local/lib/code-server && \
    ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

RUN mkdir /tmp/code-server-extensions && cd /tmp/code-server-extensions && \
    wget -O rtools.gz https://marketplace.visualstudio.com/_apis/public/gallery/publishers/Ikuyadeu/vsextensions/r/1.2.7/vspackage && \
    gunzip rtools.gz && \
    mv rtools /home/coder/rtools.vsix && \
    code-server --install-extension /home/coder/rtools.vsix && \
    rm /home/coder/rtools.vsix


ENV PATH=/home/coder/.local/bin:$PATH

EXPOSE 8080
USER coder
WORKDIR /home/coder
ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/local/bin/code-server", "--host", "0.0.0.0", "."]
