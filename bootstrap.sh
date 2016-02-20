#!/bin/sh
set -e
git submodule update --init --recursive --remote
autoreconf --install
case `uname` in Darwin*) glibtoolize ;;
  *) libtoolize ;; esac
aclocal
automake --force-missing --add-missing
autoreconf
(cd libtexpdf; autoreconf -I m4)
sed 's/rm -f core/rm -f/' configure > config.cache
mv config.cache configure
chmod +x configure
