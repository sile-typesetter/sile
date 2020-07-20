#!/usr/bin/env bash

set -e
set -o pipefail

TS=$(mktemp)
trap 'rm -rf $TS' EXIT SIGHUP SIGTERM

for f in configure aclocal.m4; do
    if [[ -f $f ]]; then
        touch -r $f $TS
        sed -i -e '/rm -f/s/ core / /' $f
        touch -r $TS $f
    fi
done
