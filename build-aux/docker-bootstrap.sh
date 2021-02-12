#!/usr/bin/env sh
set -e

# GitHub Actions runner gives us jack squat
if [ ! -e ".git" ]; then
    jq -Mer '.version + "-unknown"' package.json > .tarball-version

# Docker Hub gives us a Git working directory, but with depth=1
else
    git fetch --unshallow ||:
    git fetch --tags ||:
fi
