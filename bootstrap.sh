#!/usr/bin/env sh

# We neet a local copy of the libtexpdf library to compile. If this was
# downloaded as a src distibution package this will exist already, but if not
# and we are part of a git repository that the user has not fully initialized,
# go ahead and do the step of fetching the the submodule so the compile process
# can run.
if [ ! -f "libtexpdf/configure.ac" ] && [ -d ".git" ]; then
    git submodule update --init --recursive --remote
fi

autoreconf --install
(cd libtexpdf; autoreconf -I m4)
sed -i -e 's/rm -f core/rm -f/' configure
