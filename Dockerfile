ARG ARCHTAG

FROM docker.io/library/archlinux:base-devel-$ARCHTAG AS builder

# This is a hack to convince Docker Hub that its cache is behind the times.
# This happens when the contents of our dependencies changes but the base
# system hasn’t been refreshed. It’s helpful to have this as a separate layer
# because it saves a lot of time for local builds, but it does periodically
# need a poke. Incrementing this when changing dependencies or just when the
# remote Docker Hub builds die should be enough.
ARG DOCKER_HUB_CACHE=0

ARG RUNTIME_DEPS
ARG BUILD_DEPS

# Freshen all base system packages
RUN pacman --needed --noconfirm -Syuq

# Install run-time dependecies (increment cache var above)
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS $BUILD_DEPS

# Set at build time, forces Docker’s layer caching to reset at this point
ARG VCS_REF=0

COPY ./ /src
WORKDIR /src

# GitHub Actions builder stopped providing git history :(
# See feature request at https://github.com/actions/runner/issues/767
RUN build-aux/bootstrap-docker.sh

RUN ./bootstrap.sh
RUN ./configure
RUN make
RUN make check
RUN make install DESTDIR=/pkgdir

# Work around BuiltKit / buildx bug, they can’t copy to symlinks only dirs
RUN mv /pkgdir/usr/local/{share/,}/man

FROM docker.io/library/archlinux:base-$ARCHTAG AS final

# Same args as above, repeated because they went out of scope with FROM
ARG VCS_REF=0
ARG DOCKER_HUB_CACHE=0
ARG RUNTIME_DEPS

# Freshen all base system packages (and cleanup cache)
RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Install run-time dependecies
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS && yes | pacman -Sccq

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$VCS_REF"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf

COPY --from=builder /pkgdir /
RUN sile --version

WORKDIR /data
ENTRYPOINT ["sile"]
