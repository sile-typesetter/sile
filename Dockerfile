FROM archlinux

ARG sile_tag=master

LABEL maintainer='Caleb Maclennan <caleb@alerque.com>'
LABEL version="$sile_tag"

RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

COPY build-aux/build-for-docker.sh /usr/local/bin/
RUN build-for-docker.sh

COPY build-aux/docker-entrypoint.sh /usr/local/bin

WORKDIR /data
ENTRYPOINT ["docker-entrypoint.sh"]
