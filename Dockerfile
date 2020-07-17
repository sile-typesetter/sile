ARG sile_tag=master
FROM archlinux:20200306 AS sile-base
RUN sed -i -e '/IgnorePkg *=/s/^.*$/IgnorePkg = coreutils/' /etc/pacman.conf

RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

RUN pacman --needed --noconfirm -Syq lua fontconfig harfbuzz icu gentium-plus-font && yes | pacman -Sccq

FROM sile-base AS sile-builder

RUN pacman --needed --noconfirm -Syq git base-devel poppler luarocks libpng

COPY ./ /src
WORKDIR /src

RUN mkdir /pkgdir

RUN git clean -dxf ||:
RUN git fetch --unshallow ||:
RUN git fetch --tags ||:

RUN ./bootstrap.sh
RUN ./configure
RUN make
RUN make check
RUN make install DESTDIR=/pkgdir

FROM sile-base AS sile

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$sile_tag"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf

COPY --from=sile-builder /pkgdir /
RUN sile --version

WORKDIR /data
ENTRYPOINT ["sile"]
