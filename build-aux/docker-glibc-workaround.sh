#!/usr/bin/env sh
set -e

# Temporary workaround for glibc 2.33 having new syscalls that are not
# whitelisted yet in some older Docker host environments including the engines
# on GitHub Actions and Docker Hub.
#
# Arch Linux bug report:
# https://gitlab.archlinux.org/archlinux/archlinux-docker/-/issues/56
#
# Upstream GitHub issue (also affects Docker Hub):
# https://github.com/actions/virtual-environments/issues/2658
#
# Dockerfile workaround thanks to:
# https://github.com/lxqt/lxqt-panel/pull/1562
#
# Patched glibc sources here:
# https://github.com/archlinuxcn/repo/tree/master/archlinuxcn/glibc-linux4

cd /tmp

pkgfile='glibc-linux4-2.33-4-x86_64.pkg.tar.zst'
sha256sum='a89f4d23ae7cde78b4258deec4fcda975ab53c8cda8b5e0a0735255c0cdc05cc'

check_checksum () {
    echo "$sha256sum $pkgfile" | sha256sum -c
}

check_checksum ||
    curl -LO "https://repo.archlinuxcn.org/x86_64/$pkgfile" &&
    check_checksum

bsdtar -C / -xvf "$pkgfile" 2>/dev/null

sed -e '/^HoldPkg/s/^/#/' -i /etc/pacman.conf

pacman --noconfirm --dbonly -Rdd glibc
pacman --noconfirm --overwrite '*' -Udd "$pkgfile"

sed -e '/^#\?IgnorePkg/{s/^#//;s/$/ glibc/}' -i /etc/pacman.conf

rm "$pkgfile"
