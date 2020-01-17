ARG sile_tag=master
FROM archlinux AS sile-base

RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

COPY build-aux/docker-yay-runner.sh /usr/local/bin
RUN docker-yay-runner.sh --needed --noconfirm -S \
		fontconfig harfbuzza icu lua ttf-gentium-plus \
		lua-{luaepnf,lpeg,cassowary,linenoise,zlib,cliargs,filesystem,repl} \
		lua-{sec,socket,penlight,stdlib,vstruct}

FROM sile-base AS sile-builder

RUN pacman --needed --noconfirm -S git base-devel

COPY ./ /src
WORKDIR /src

RUN mkdir /pkgdir

RUN ./bootstrap.sh && ./configure --with-system-luarocks && make
RUN make install DESTDIR=/pkgdir

FROM sile-base AS sile

LABEL maintainer="Caleb Maclennan <caleb@alerque.com>"
LABEL version="$sile_tag"

COPY build-aux/docker-entrypoint.sh /usr/local/bin

COPY --from=sile-builder /pkgdir /

WORKDIR /data
ENTRYPOINT ["docker-entrypoint.sh"]
