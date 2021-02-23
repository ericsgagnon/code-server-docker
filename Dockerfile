# docker build --pull -t ericsgagnon/code-server:dev -f ./Dockerfile .
# docker run -it --rm --name code-server -p 9101:8080 --entrypoint="/bin/bash" ericsgagnon/code-server:dev
# docker run --rm --name code-server --gpus all ericsgagnon/code-server:dev nvidia-smi
# docker logs code-server
# docker rm -fv code-server
# docker push ericsgagnon/code-server:3.1.1

# Description: ##################################################
# code-server with as many up-to-date, pre-installed tools as I 
# can manage.
# ###############################################################

####################################################################
# Image ############################################################
FROM ericsgagnon/ide-base:dev as base

# ENV DEBIAN_FRONTEND=noninteractive
# ENV TZ=America/New_York
# ENV LANG=en_US.UTF-8
# ENV PASSWORD password

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

USER root

# ENV CODE_SERVER_VERSION=${CODE_SERVER_VERSION}

# RUN echo "alias ll='ls -alh '" >> /etc/skel/.bashrc && \
#     echo "source <(kubectl completion bash)" >> /etc/skel/.bashrc && \
#     echo "source <(helm completion bash)" >> /etc/skel/.bashrc && \
#     sed -i -r 's/^(export PATH.*)/\1:$PATH/g' /etc/skel/.bashrc && \
#     deluser --remove-home rstudio && \
#     adduser --gecos '' --disabled-password coder && \
#     echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml




RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

RUN cd /tmp && \
    wget https://github.com/cdr/code-server/releases/download/${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf code-server*.tar.gz && rm code-server*.tar.gz && \
    mv code-server* /usr/local/lib/code-server && \
    ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

# RUN mkdir /tmp/code-server-extensions && cd /tmp/code-server-extensions && \
#     wget -O rtools.gz https://marketplace.visualstudio.com/_apis/public/gallery/publishers/Ikuyadeu/vsextensions/r/1.2.7/vspackage && \
#     gunzip rtools.gz && \
#     mv rtools /home/coder/rtools.vsix && \
#     code-server --install-extension /home/coder/rtools.vsix && \
#     rm /home/coder/rtools.vsix

RUN curl -fsSL https://code-server.dev/install.sh | sh \
    && which code-server \
    && coder-server --version

ENV PATH=/home/coder/.local/bin:$PATH

EXPOSE 8080
USER coder
WORKDIR /home/coder

COPY release-packages/code-server*.deb /tmp/
COPY entrypoint.sh /usr/bin/entrypoint.sh

EXPOSE 8080
# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER 1000
ENV USER=coder
WORKDIR /home/coder

ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/local/bin/code-server", "--host", "0.0.0.0", "."]
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]