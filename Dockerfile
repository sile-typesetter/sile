#syntax=docker/dockerfile:1.2

ARG ARCHTAG

FROM docker.io/library/archlinux:base-devel$ARCHTAG AS builder

ARG RUNTIME_DEPS
ARG BUILD_DEPS

# Enable system locales for everything we have localizations for so tools like
# `date` will output matching localized strings. By default Arch Docker images
# have almost all locale data stripped out. This also makes it easier to
# rebuild custom Docker images with extra languages supported.
RUN sed -i -e '/^NoExtract.*locale/d' /etc/pacman.conf

# Freshen all base system packages
RUN pacman-key --init
RUN pacman --needed --noconfirm -Syq archlinux-keyring
RUN pacman --needed --noconfirm -Suq

# Make sure *at least* glibc actually got reinstalled after enabling
# extraaction of locale files even if the version was fresh so we can use the
# locale support out of it later.
RUN pacman --noconfirm -Sq glibc && yes | pacman -Sccq

# Install run-time dependecies
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS $BUILD_DEPS

# Set at build time, forces Docker’s layer caching to reset at this point
ARG REVISION

COPY ./ /src
WORKDIR /src

# Rebuild locale database after having added our supported locales.
RUN ls i18n/ | sed 's/[.-].*$/_/;s/^/^/' | sort -u | grep -Ef - /usr/share/i18n/SUPPORTED > /etc/locale.gen
RUN locale-gen

# GitHub Actions builder stopped providing git history :(
# See feature request at https://github.com/actions/runner/issues/767
RUN build-aux/docker-bootstrap.sh

RUN ./bootstrap.sh
RUN ./configure --with-system-lua-sources --without-manual
RUN make
RUN make install DESTDIR=/pkgdir

# Work around BuiltKit / buildx bug, they can’t copy to symlinks only dirs
RUN mv /pkgdir/usr/local/{share/,}/man

FROM docker.io/library/archlinux:base$ARCHTAG AS final

# Same args as above, repeated because they went out of scope with FROM
ARG RUNTIME_DEPS
ARG VERSION
ARG REVISION

# Allow `su` with no root password so non-priv users can install dependencies
RUN sed -i -e '/.so$/s/$/ nullok/' /etc/pam.d/su

# Set system locale to something other than 'C' that resolves to a real language
ENV LANG=en_US.UTF-8

# Freshen all base system packages (and cleanup cache)
RUN pacman-key --init
RUN pacman --needed --noconfirm -Syq archlinux-keyring && yes | pacman -Sccq
RUN pacman --needed --noconfirm -Suq && yes | pacman -Sccq

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
COPY --from=builder /src/src/sile-entry.sh /usr/local/bin
RUN sile --version

WORKDIR /data
ENTRYPOINT [ "sile-entry.sh" ]
