#!/usr/bin/env sh
set -e

incomplete_source () {
    echo -e "$1. Please either:\n" \
            "* $2,\n" \
            "* or use the source packages instead of a repo archive\n" \
            "* or use a full Git clone.\n" >&2
    exit 1
}

# We neet a local copy of the libtexpdf library to compile. If this was
# downloaded as a src distibution package this will exist already, but if not
# and we are part of a git repository that the user has not fully initialized,
# go ahead and do the step of fetching the the submodule so the compile process
# can run.
if [ ! -f "libtexpdf/configure.ac" ]; then
    if [ -e ".git" ]; then
        git submodule update --init --recursive --remote
    else
        incomplete_source "No libtexpdf sources found" \
            "download and extract a copy yourself"
    fi
fi

# Make
# directory. This enables easy building from Github's snapshot archives
if [ ! -e ".git" ] && [ ! -f ".tarball-version" ]; then
    incomplete_source "No version information found" \
        "identify the correct version with \`echo \$version > .tarball-version\`"
fi

touch -t 197001010200 Makefile-distfiles

autoreconf --install -W none

# See discussion in https://github.com/sile-typesetter/sile/issues/82 and
# https://web.archive.org/web/20170111053341/http://blog.gaku.net/autoconf/
case `uname` in
    Darwin*) glibtoolize -W none ;;
    *)        libtoolize -W none ;;
esac
aclocal --force -W none
automake --force-missing --add-missing -W none
autoreconf --force -W none

sed -i -e '/rm -f/s/ core / /' configure aclocal.m4 ||:

(cd libtexpdf; autoreconf)
