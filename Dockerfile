FROM docker.io/library/archlinux:base-devel AS sile-builder

# This is a hack to convince Docker Hub that its cache is behind the times.
# This happens when the contents of our dependencies changes but the base
# system doesn't have a fresh package list. It's helpful to have this in a
# separate layer because it saves a lot of time for local builds, but it does
# periodically need a poke. Incrementing this when changing dependencies or
# just when the remote Docker Hub builds die should be enough.
ARG DOCKER_HUB_CACHE=0

ARG RUNTIME_DEPS="fontconfig freetype2 gentium-plus-font harfbuzz icu lua"
ARG BUILD_DEPS="git libpng luarocks poppler zlib"

# Freshen all base system packages
RUN pacman --needed --noconfirm -Syuq

# Install build and run-time dependecies
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS $BUILD_DEPS

# Set at build time, forces Docker's layer caching to reset at this point on
# source repository changes
ARG VCS_REF=0

COPY ./ /src
WORKDIR /src

RUN mkdir /pkgdir

RUN git clean -dxf -e .fonts -e .sources ||:
RUN git fetch --unshallow ||:
RUN git fetch --tags ||:

RUN ./bootstrap.sh
RUN ./configure
RUN make
RUN make check
RUN make install DESTDIR=/pkgdir

FROM docker.io/library/archlinux:base AS sile

# Same args as above, repeated because they went out of scope with FROM
ARG VCS_REF=0
ARG DOCKER_HUB_CACHE=0
ARG RUNTIME_DEPS="fontconfig freetype2 gentium-plus-font harfbuzz icu lua"

# Freshen all base system packages (and cleanup cache)
RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Install run-time dependecies
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS && yes | pacman -Sccq

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$VCS_REF"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf

COPY --from=sile-builder /pkgdir /
RUN sile --version

WORKDIR /data
ENTRYPOINT ["sile"]
