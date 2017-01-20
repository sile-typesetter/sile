#!/bin/sh
cd $APPVEYOR_BUILD_FOLDER
source .travis/setenv_lua.sh
lua -e "print('Hello ' .. _VERSION .. '!')"
./bootstrap.sh || exit 1
./configure || exit 1
make || exit 1