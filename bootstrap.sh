#!/usr/bin/env sh

git submodule update --init --recursive --remote
autoreconf --install
(cd libtexpdf; autoreconf -I m4)
sed 's/rm -f core/rm -f/' -i configure
