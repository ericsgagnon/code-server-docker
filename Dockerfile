# docker build -t ericsgagnon/code-server:dev .
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

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
ENV LANG=en_US.UTF-8


# R ###################################
#COPY --from=rlang  /usr/local/lib/R /usr/local/lib/R
# COPY --from=rlang  /usr/local/bin/R /usr/local/bin/R
# COPY --from=rlang  /usr/lib         /usr/lib
# COPY --from=rlang  /lib             /lib

RUN apt update -y && apt upgrade -y && \
    apt install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libblas-dev \
    libbz2-1.0 \
    libcurl3 \
    #libicu57 \
    libicu60 \
    #libjpeg62-turbo \
    libjpeg-turbo8 \
    libjpeg-turbo8-dev \
    libjpeg-turbo8-dbg \
    libopenblas-dev \
    libpangocairo-1.0-0 \
    libpcre3 \
    libpng16-16 \
    libreadline7 \
    libtiff5 \
    liblzma5 \
    locales \
    make \
    unzip \
    zip \
    zlib1g 


RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.utf8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
		apt update -y && apt upgrade -y && \
    apt install -y \
    r-base-dev \
    r-recommended \
    littler \
    python-rpy2 \
    jags \
    ess

RUN apt install -y --no-install-recommends \
    curl \
    default-jdk \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre3-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    tcl8.6-dev \
    tk8.6-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    zlib1g-dev

#/etc/R/Rprofile.site
#/etc/R/Renviron

RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /etc/R/Rprofile.site \
  && [ -z "$BUILD_DATE" ] && BUILD_DATE=$(TZ="America/Los_Angeles" date -I) || true \
  && MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE} \
  && echo MRAN=$MRAN >> /etc/environment \
  && export MRAN=$MRAN \
  && echo "options(repos = c(CRAN='$MRAN'), download.file.method = 'libcurl')" >> /etc/R/Rprofile.site \
  ## Use littler installation scripts
  && Rscript -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" \
  && ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
  && ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
  && ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r

# go ########################################################
COPY --from=golang  /usr/local/go /usr/local/go
COPY --from=golang  /go           /go

ENV GOLANG_VERSION=${GOLANG_VERSION}
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
#RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN chmod -R 777 "$GOPATH"
RUN chsh -s /bin/bash

ENV SHELL=/bin/bash
ENV CODE_SERVER_VERSION=${CODE_SERVER_VERSION}

# code-server ###############################################

RUN apt install -y --no-install-recommends \
    sudo \
    curl \
    dumb-init \
    htop \
    locales \
    man \
    nano \
    git \
    procps \
    ssh \
    sudo \
    vim && \
    adduser --gecos '' --disabled-password coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

RUN cd /tmp && \
    wget https://github.com/cdr/code-server/releases/download/3.0.1/code-server-3.0.1-linux-x86_64.tar.gz && \
    tar -xzf code-server*.tar.gz && rm code-server*.tar.gz && \
    mv code-server* /usr/local/lib/code-server && \
    ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

EXPOSE 8080
USER coder
WORKDIR /home/coder
ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/local/bin/code-server", "--host", "0.0.0.0", "."]


wget -O rtools.gz https://marketplace.visualstudio.com/_apis/public/gallery/publishers/Ikuyadeu/vsextensions/r/1.2.7/vspackage && \
gunzip rtools.gz && \
mv rtools.gz rtools.vsix

sudo apt install -y python3.8 python3.8-dbg python3.8-dev


#echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron