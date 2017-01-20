#!/bin/sh
cd $APPVEYOR_BUILD_FOLDER

# Pretend we are on travis so that the Lua build code can be reused
export TRAVIS_BUILD_DIR=/c/projects/sile/
export TRAVIS_OS_NAME=mingw
export LUAROCKS=2.2.2
source .travis/setenv_lua.sh

lua -e "print('Hello ' .. _VERSION .. '!')"
./bootstrap.sh || exit 1
./configure || exit 1
make || exit 1