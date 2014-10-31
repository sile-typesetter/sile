#!/bin/sh
git submodule update --init --recursive
autoreconf --install
(cd libtexpdf; autoreconf)
sed 's/rm -f core/rm -f/' configure > config.cache
mv config.cache configure
chmod +x configure
