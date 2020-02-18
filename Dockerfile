ARG sile_tag=master
FROM archlinux AS sile-base

# Setup Alerque's hosted Arch repository with prebuilt dependencies
RUN pacman-key --init && pacman-key --populate
RUN sed -i -e '/^.community/{n;n;s!^!\n\[alerque\]\nServer = https://arch.alerque.com/$arch\n!}' /etc/pacman.conf
RUN pacman-key --recv-keys 63CC496475267693 && pacman-key --lsign-key 63CC496475267693

RUN pacman --needed --noconfirm -Syuq && yes | pacman -Sccq

# Installing and removing pre-packaged sile bootstraps the system dependencies
RUN pacman --needed --noconfirm -Syq sile && yes | pacman -Sccq && pacman --noconfirm -Rq sile

FROM sile-base AS sile-builder

RUN pacman --needed --noconfirm -Syq git base-devel poppler

COPY ./ /src
WORKDIR /src

RUN mkdir /pkgdir

RUN git clean -dxf ||:
RUN git fetch --unshallow ||:
RUN git fetch --tags ||:

RUN ./bootstrap.sh
RUN ./configure --with-system-luarocks
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
