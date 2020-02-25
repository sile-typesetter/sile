ARG sile_tag=master
FROM archlinux AS sile-base

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
RUN make install DESTDIR=/pkgdir

FROM sile-base AS sile

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$sile_tag"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf
COPY build-aux/docker-entrypoint.sh /usr/local/bin

COPY --from=sile-builder /pkgdir /

WORKDIR /data
ENTRYPOINT ["docker-entrypoint.sh"]
