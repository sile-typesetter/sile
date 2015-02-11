#!/bin/sh
git submodule update --init --recursive
autoreconf --install
(cd libtexpdf; autoreconf; aclocal -Im4; autoconf)
sed 's/rm -f core/rm -f/' configure > config.cache
mv config.cache configure
chmod +x configure
