#!/usr/bin/env sh
set -e

# We neet a local copy of the libtexpdf library to compile. If this was
# downloaded as a src distibution package this will exist already, but if not
# and we are part of a git repository that the user has not fully initialized,
# go ahead and do the step of fetching the the submodule so the compile process
# can run.
if [ ! -f "libtexpdf/configure.ac" ] && [ -e ".git" ]; then
    git submodule update --init --recursive --remote
fi

autoreconf --install

# See discussion in https://github.com/sile-typesetter/sile/issues/82 and
# https://web.archive.org/web/20170111053341/http://blog.gaku.net/autoconf/
case `uname` in
    Darwin*) glibtoolize ;;
    *)        libtoolize ;;
esac
aclocal --force
automake --force-missing --add-missing
autoreconf --force

(cd libtexpdf; autoreconf -I m4)
