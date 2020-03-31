# docker build -t ericsgagnon/scratch:scratch -f ./scratch.dockerfile .
# code-server with more up to date versions of languages:
# docker run -dit --name scratch -p 9101:8080 ericsgagnon/scratch:scratch
# docker logs scratch
# docker rm -fv scratch

ARG R_VERSION=3.6.2

FROM rocker/geospatial:${R_VERSION} as rlang

FROM buildpack-deps:bionic

# R ###################################
COPY --from=rlang  /usr/local/lib/R /usr/local/lib/R
COPY --from=rlang  /usr/local/bin/R /usr/local/bin/R
#COPY --from=rlang  /usr/lib         /usr/lib
#COPY --from=rlang  /lib             /lib

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
ENV LANG=en_US.UTF-8

# code-server ###############################################

RUN apt update && apt install -y --no-install-recommends \
    sudo \
    dumb-init \
    htop \
    locales \
    man \
    nano \
    procps \
    ssh \
    vim

#    curl \
#    git \

RUN adduser --gecos '' --disabled-password coder && \
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


# enable security updates repo
#RUN echo "deb http://security.debian.org/ buster/updates main contrib non-free" >> /etc/apt/sources.list && \
#    echo "deb http://deb.debian.org/debian buster-proposed-updates main contrib non-free" >> /etc/apt/sources.list && \
#		apt update -y && apt upgrade -y


#RUN apt install -y \
#  libnss-wrapper
