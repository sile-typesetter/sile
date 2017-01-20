#!/bin/sh
cd $APPVEYOR_BUILD_FOLDER
export TRAVIS_OS_NAME=mingw64
source .travis/setenv_lua.sh
lua -e "print('Hello ' .. _VERSION .. '!')"
./bootstrap.sh || exit 1
./configure || exit 1
make || exit 1