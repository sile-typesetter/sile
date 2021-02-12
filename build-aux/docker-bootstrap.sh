#!/usr/bin/env sh
set -e

# GitHub Actions runner gives us jack squat
if [ ! -e ".git" ]; then
    jq -Mer '.version + "-unknown"' package.json > .tarball-version

# Docker Hub gives us a Git working directory, but with depth=1
else
    git fetch --unshallow ||:
    git fetch --tags ||:

    # When copying the source from a working directory that has been configured for
    # a local system it is possible to have values in the configure cache that will
    # causue the Docker build to fail. The root cause here is the submodule build
    # process installing the completed build to the local source tree as a side
    # effect. Remove this hack after fixing the _BUILT_SUBDIRS hack is resolved.
    ( cd libtexpdf && git clean -dxff ||: )

fi
