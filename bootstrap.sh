#!/bin/sh
touch NEWS README AUTHORS THANKS ChangeLog # HATE YOU GNU
git submodule update --init --recursive
autoreconf --install
(cd libtexpdf; autoreconf)
sed 's/core conftest.err/conftest.err/' configure > config.cache
mv config.cache configure
chmod +x configure
