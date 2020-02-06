ARG sile_tag=master
FROM archlinux AS sile-base

RUN pacman --needed --noconfirm -Syyuq && yes | pacman -Sccq

COPY build-aux/docker-yay-runner.sh /usr/local/bin
RUN docker-yay-runner.sh "--noconfirm --asexplicit -Sq fontconfig harfbuzz icu lua lua-{cassowary,cosmo,cliargs,expat,filesystem,linenoise,lpeg,luaepnf,penlight,repl,sec,socket,stdlib,vstruct,zlib} ttf-gentium-plus"

FROM sile-base AS sile-builder

RUN pacman --needed --noconfirm -Syyuq && pacman --needed --noconfirm -Sq git base-devel poppler && yes | pacman -Sccq

COPY ./ /src
WORKDIR /src

RUN mkdir /pkgdir

RUN git clean -dxf ||:
RUN git fetch --unshallow ||:
RUN git fetch --tags ||:

RUN ./bootstrap.sh && ./configure --with-system-luarocks && make
RUN make install DESTDIR=/pkgdir

FROM sile-base AS sile

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$sile_tag"

COPY build-aux/docker-fontconfig.conf /etc/fonts/conf.d/99-docker.conf
COPY build-aux/docker-entrypoint.sh /usr/local/bin

COPY --from=sile-builder /pkgdir /

WORKDIR /data
ENTRYPOINT ["docker-entrypoint.sh"]
