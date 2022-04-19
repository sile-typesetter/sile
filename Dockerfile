#syntax=docker/dockerfile:1.2

ARG ARCHTAG

FROM docker.io/library/archlinux:base-devel$ARCHTAG AS builder

ARG RUNTIME_DEPS
ARG BUILD_DEPS

# Monkey patch glibc to avoid issues with old kernels on hosts
RUN --mount=type=bind,target=/mp,source=build-aux/docker-glibc-workaround.sh /mp

# Freshen all base system packages
RUN pacman --needed --noconfirm -Syuq

# Install run-time dependecies
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS $BUILD_DEPS

# Set at build time, forces Docker’s layer caching to reset at this point
ARG REVISION

COPY ./ /src
WORKDIR /src

# GitHub Actions builder stopped providing git history :(
# See feature request at https://github.com/actions/runner/issues/767
RUN build-aux/docker-bootstrap.sh

RUN ./bootstrap.sh
RUN ./configure --without-manual
RUN make
RUN make check
RUN make install DESTDIR=/pkgdir

# Work around BuiltKit / buildx bug, they can’t copy to symlinks only dirs
RUN mv /pkgdir/usr/local/{share/,}/man

FROM docker.io/library/archlinux:base$ARCHTAG AS final

# Same args as above, repeated because they went out of scope with FROM
ARG RUNTIME_DEPS
ARG VERSION
ARG REVISION

# Monkey patch glibc to avoid issues with old kernels on hosts
RUN --mount=type=bind,target=/mp,source=build-aux/docker-glibc-workaround.sh /mp

# Freshen all base system packages (and cleanup cache)
RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Install run-time dependecies
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS && yes | pacman -Sccq

LABEL org.opencontainers.image.title="SILE"
LABEL org.opencontainers.image.description="A containerized version of the SILE typesetter"
LABEL org.opencontainers.image.authors="Caleb Maclennan <caleb@alerque.com>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/sile-typesetter/sile/pkgs/container/sile"
LABEL org.opencontainers.image.source="https://github.com/sile-typesetter/sile"
LABEL org.opencontainers.image.version="v$VERSION"
LABEL org.opencontainers.image.revision="$REVISION"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf

COPY --from=builder /pkgdir /
RUN sile --version

WORKDIR /data
ENTRYPOINT ["sile"]
