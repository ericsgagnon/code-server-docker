# docker build --pull -t ericsgagnon/code-server:dev -f ./Dockerfile .
# docker run -it --rm --name code-server -p 9101:8080 --entrypoint="/bin/bash" ericsgagnon/code-server:dev
# docker run -dit --name code-server -p 9101:8080 --gpus all ericsgagnon/code-server:dev
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


# code-server #############################################

# RUN echo "alias ll='ls -alh '" >> /etc/skel/.bashrc && \
#     echo "source <(kubectl completion bash)" >> /etc/skel/.bashrc && \
#     echo "source <(helm completion bash)" >> /etc/skel/.bashrc && \
#     sed -i -r 's/^(export PATH.*)/\1:$PATH/g' /etc/skel/.bashrc && \
#     deluser --remove-home rstudio && \
#     adduser --gecos '' --disabled-password coder && \
#     echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN curl -fsSL https://code-server.dev/install.sh | sh
#   && which code-server \
#   && coder-server --version

# RUN mkdir /tmp/code-server-extensions && cd /tmp/code-server-extensions && \
#     wget -O rtools.gz https://marketplace.visualstudio.com/_apis/public/gallery/publishers/Ikuyadeu/vsextensions/r/1.2.7/vspackage && \
#     gunzip rtools.gz && \
#     mv rtools /home/coder/rtools.vsix && \
#     code-server --install-extension /home/coder/rtools.vsix && \
#     rm /home/coder/rtools.vsix

#ENV PATH=/home/coder/.local/bin:$PATH

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod 0755 /usr/bin/entrypoint.sh

RUN mkdir -p /etc/skel/.local/share/code-server

# USER liveware
ENV USER=liveware
ENV GROUP=liveware
RUN printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

# WORKDIR /home/liveware
ENV PASSWORD=password
#ENV HASHED_PASSWORD
ENV SERVICE_URL=https://open-vsx.org/vscode/gallery
ENV ITEM_URL=https://open-vsx.org/vscode/item

ENV SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery
ENV ITEM_URL=https://marketplace.visualstudio.com/items

EXPOSE 8080

#USER 1138
#WORKDIR /home/coder
#ENTRYPOINT ["/usr/bin/entrypoint.sh"]


# s6 process manager ######################################################
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.1/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /

# s6 initialization
COPY userconf.sh /etc/cont-init.d/
# s6 services 
COPY code-server.sh /etc/services.d/code-server/run
# s6 finish

ENTRYPOINT ["/init"]











