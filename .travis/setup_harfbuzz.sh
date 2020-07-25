#!/usr/bin/env bash

if [ ! -f $HOME/local/include/harfbuzz/hb.h ]; then
    mkdir -p $HOME/local
    mkdir -p $HOME/builddeps
    cd $HOME/builddeps
    wget https://github.com/harfbuzz/harfbuzz/archive/$1.tar.gz
    tar xfz $1.tar.gz
    cd harfbuzz-$1
    ./autogen.sh --with$($GRAPHITE || echo 'out')-graphite2 --prefix=$HOME/local/
    make
    make install
fi
