#!/usr/bin/env sh
set -e

incomplete_source () {
    printf '%s\n' \
        "$1. Please either:" \
        "* $2," \
        "* or use the source packages instead of a repo archive" \
        "* or use a full Git clone." >&2
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

# This enables easy building from Github's snapshot archives
if [ ! -e ".git" ]; then
    if [ ! -f ".tarball-version" ]; then
    incomplete_source "No version information found" \
        "identify the correct version with \`echo \$version > .tarball-version\`"
    fi
else
    # Just a head start to save a ./configure cycle
    ./build-aux/git-version-gen .tarball-version > .version
fi

autoreconf --install

# See discussion in https://github.com/sile-typesetter/sile/issues/82 and
# https://web.archive.org/web/20170111053341/http://blog.gaku.net/autoconf/
case $(uname) in
    Darwin*)
        glibtoolize -W none
        autoreconf --force -W none
        ;;
esac

build-aux/decore-automake.sh
