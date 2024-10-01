#syntax=docker/dockerfile:1.2

ARG ARCHTAG

FROM docker.io/library/archlinux:$ARCHTAG AS base

# Initialize keys so we can do package management
RUN pacman-key --init && pacman-key --populate

# This hack can convince Docker its cache is obsolete; e.g. when the contents
# of downloaded resources have changed since being fetched. It's helpful to have
# this as a separate layer because it saves time for local builds. Incrementing
# this when pushing dependency updates to Caleb's Arch user repository or just
# when the remote Docker Hub builds die should be enough.
ARG DOCKER_HUB_CACHE=1

ARG RUNTIME_DEPS

# Enable system locales for everything we have localizations for so tools like
# `date` will output matching localized strings. By default Arch Docker images
# have almost all locale data stripped out. This also makes it easier to
# rebuild custom Docker images with extra languages supported.
RUN sed -i -e '/^NoExtract.*locale/d' /etc/pacman.conf

# Freshen all base system packages
RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Make sure *at least* glibc actually got reinstalled after enabling
# extraction of locale files even if the version was fresh so we can use the
# locale support out of it later.
RUN pacman --noconfirm -Sq glibc && yes | pacman -Sccq

# Install run-time dependencies
RUN pacman --needed --noconfirm -Sq $RUNTIME_DEPS && yes | pacman -Sccq

# Setup LuaRocks for use with LuaJIT roughly matching SILE's internal VM
RUN luarocks config lua_version 5.1 && \
    luarocks config lua_interpreter luajit && \
    luarocks config variables.LUA "$(command -v luajit)" && \
    luarocks config variables.LUA_INCDIR /usr/include/luajit-2.1/

# Setup separate image for build so we don’t bloat the final image
FROM base AS builder

ARG BUILD_DEPS

# Install build time dependencies
RUN pacman --needed --noconfirm -Sq $BUILD_DEPS && yes | pacman -Sccq

# Set at build time, forces Docker’s layer caching to reset at this point
ARG REVISION

COPY ./ /src
WORKDIR /src

# Take note of SILE's supported locales so the final system can build localized messages
RUN ls i18n/ | sed 's/[.-].*$/_/;s/^/^/' | sort -u | grep -Ef - /usr/share/i18n/SUPPORTED > /etc/locale.gen

# GitHub Actions builder stopped providing git history :(
# See feature request at https://github.com/actions/runner/issues/767
RUN build-aux/docker-bootstrap.sh

# Use clang and mold instead of gcc and ld for speed
ENV RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=mold"

RUN ./bootstrap.sh
RUN ./configure \
        --disable-embeded-resources \
        --with-system-lua-sources \
        --without-system-luarocks \
        --without-manual
RUN make
RUN make install DESTDIR=/pkgdir

FROM base AS final

# Same args as above, repeated because they went out of scope with FROM
ARG REVISION
ARG VERSION

# Allow `su` with no root password so non-priv users can install dependencies
RUN sed -i -e '/.so$/s/$/ nullok/' /etc/pam.d/su

# Set system locale to something other than 'C' that resolves to a real language
ENV LANG=en_US.UTF-8

# Rebuild locale database so system apps have localized messages for SILE's supported locales
COPY --from=builder /etc/locale.gen /etc
RUN locale-gen

LABEL org.opencontainers.image.title="SILE"
LABEL org.opencontainers.image.description="A containerized version of the SILE typesetter"
LABEL org.opencontainers.image.authors="Caleb Maclennan <caleb@alerque.com>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/sile-typesetter/sile/pkgs/container/sile"
LABEL org.opencontainers.image.source="https://github.com/sile-typesetter/sile"
LABEL org.opencontainers.image.version="v$VERSION"
LABEL org.opencontainers.image.revision="$REVISION"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf

# Inform the system Lua manifest where SILE's vendored modules are so they are
# available to 3rd party packages even outside of SILE's runtime. Most notably
# useful so that luarocks can find them as existing dependencies when
# installing 3rd party modules. We replace the user tree instead of inserting
# a new one because it doesn't make sense in Docker anyway and the default
# priority works out better having it first.
RUN luarocks config rocks_trees[1].root /usr/local/share/sile/lua_modules && \
    luarocks config rocks_trees[1].name sile && \
    luarocks config deps_mode all

COPY --from=builder /pkgdir /
COPY --from=builder /src/src/sile-entry.sh /usr/local/bin

RUN sile --version

WORKDIR /data
ENTRYPOINT [ "sile-entry.sh" ]
