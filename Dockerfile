FROM docker.io/library/archlinux:20200705 AS sile-base

# Downgrade coreutils to avoid filesystem bug on DockerHub host kernels
RUN pacman --noconfirm -U https://archive.archlinux.org/packages/c/coreutils/coreutils-8.31-3-x86_64.pkg.tar.xz
RUN sed -i -e '/IgnorePkg *=/s/^.*$/IgnorePkg = coreutils/' /etc/pacman.conf

# This is a hack to convince Docker Hub that its cache is behind the times.
# This happens when the contents of our dependencies changes but the base
# system hasn't been refreshed. It's helpful to have this as a separate layer
# because it saves a lot of time for local builds, but it does periodically
# need a poke. Incrementing this when changing dependencies or just when the
# remote Docker Hub builds die should be enough.
ARG DOCKER_HUB_CACHE=1

# Freshen all base system packages
RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Install SILE run-time dependecies (increment cache var above)
RUN pacman --needed --noconfirm -Syq \
	lua fontconfig harfbuzz icu gentium-plus-font \
	&& yes | pacman -Sccq

# Setup separate image to build SILE so we don't bloat the final image
FROM sile-base AS sile-builder

# Install build time dependecies
RUN pacman --needed --noconfirm -Syq \
	base-devel git poppler luarocks libpng

# Set at build time, forces Docker's layer caching to reset at this point
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

FROM sile-base AS sile

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$VCS_REF"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf

COPY --from=sile-builder /pkgdir /
RUN sile --version

WORKDIR /data
ENTRYPOINT ["sile"]
