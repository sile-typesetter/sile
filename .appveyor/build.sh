#!/bin/sh
cd $APPVEYOR_BUILD_FOLDER

# Pretend we are on travis so that the Lua build code can be reused
export TRAVIS_BUILD_DIR=/c/projects/sile/
export TRAVIS_OS_NAME=mingw
export LUAROCKS=2.2.2
source .travis/setenv_lua.sh
export LUA_HOME_DIR=$TRAVIS_BUILD_DIR/install/lua
export LUA=~/.lua/lua
export LUA_INCLUDE=-I$LUA_HOME_DIR/include
export LD_LIBRARY_PATH=$LUA_HOME_DIR/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$LUA_HOME_DIR/lib:$LD_LIBRARY_PATH
export LD_RUN_PATH=$LUA_HOME_DIR/lib:$LD_RUN_PATH
export PATH=.travis:$PATH

pacman -Ql mingw-w64-x86_64-zlib
pacman -Ql mingw-w64-x86_64-expat

echo "Building lpeg"
cd vendor/lpeg
make LUA_DLL=$HOME/.lua/lua*.dll LUADIR=$LUA_HOME_DIR/include mingw
mkdir -p /usr/local/lib/lua/5.3/
cp lpeg.dll /usr/local/lib/lua/5.3/lpeg.so # We'll move it to a SILE dir later
cd ../..
echo "---"

echo "Building lfs"
cd vendor/luafilesystem
make LUA_INC=$LUA_HOME_DIR/include LIB_OPTION="-shared "$HOME/.lua/lua*.dll
mkdir -p /usr/local/lib/lua/5.3/
cp src/lfs.so /usr/local/lib/lua/5.3/lfs.so
cd ../..
echo "---"

luarocks install lua-zlib ZLIB_DIR=/mingw64
luarocks install luaexpat EXPAT_DIR=/mingw64
luarocks install lua_cliargs 2.3-3
luarocks install busted
luarocks install luacov 0.8-1
luarocks install luacov-coveralls

./bootstrap.sh || exit 1
./configure || exit 1
make || exit 1