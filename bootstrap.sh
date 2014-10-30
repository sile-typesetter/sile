#!/bin/sh
git submodule update --init --recursive
autoreconf --install
(cd libtexpdf; autoreconf)
sed 's/core conftest.err/conftest.err/' configure > config.cache
mv config.cache configure
chmod +x configure
