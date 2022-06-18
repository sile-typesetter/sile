#!/usr/bin/env sh
set -e

TS=$(mktemp)
trap 'rm -rf $TS' EXIT HUP TERM

for f in configure aclocal.m4; do
    if [ -f $f ]; then
        touch -r "$f" "$TS"
        sed -i -e '/rm -f/s/ core / /' "$f"
        touch -r "$TS" "$f"
    fi
done

# Makefile.in being newer than aclocal.m4 at this point *is* important, this
# point being both dist-hook and at configure time. The former is covered by a
# side effect of a `sed` intervention, but to cover configure time changes we
# need it here too.
touch Makefile.in
