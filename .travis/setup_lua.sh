#!/usr/bin/env bash

# Don't mess with it if these are already setup (as should be the case if we
# get a cache hit on Travis)
which lua && which luarocks && exit 0 ||:

set -eufo pipefail

if [[ $1 == 2* ]]; then
    LUAJIT=true
    BASE="LuaJIT-$1"
    URL=https://luajit.org/download/$BASE.tar.gz
    BIN=luajit
else
    LUAJIT=false
    BASE="lua-$1"
    URL=https://www.lua.org/ftp/$BASE.tar.gz
    BIN=lua
fi

mkdir -p "$HOME/.lua"
mkdir -p "$LUA_HOME_DIR"
mkdir -p "$HOME/.setup_lua"

cd "$HOME/.setup_lua"

curl --location "$URL" | tar xz;
pushd $BASE

if $LUAJIT; then
    make
    make install PREFIX="$LUA_HOME_DIR"
else
  # Build Lua without backwards compatibility for testing
  perl -i -pe 's/-DLUA_COMPAT_\S+//' src/Makefile
  perl -i -pe 's/-DLUA_BUILD_AS_DLL/-DLUA_USE_POSIX -DLUA_DL_DLL -DLUA_BUILD_AS_DLL/' src/Makefile
  make linux CC="gcc -std=gnu99 -fPIC"
  make install INSTALL_TOP="$LUA_HOME_DIR"
fi

ln -sf $LUA_HOME_DIR/bin/$BIN $HOME/.lua/$BIN

popd
$BIN -v

LUAROCKS_BASE=luarocks-$2

curl --location https://luarocks.org/releases/$LUAROCKS_BASE.tar.gz | tar xz

pushd $LUAROCKS_BASE

# Travis dies if luarocks' configure script runs a command that's redirected to dev null
sed -i -e '/^make clean/s/>.*//' ./configure

if $LUAJIT; then
  ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.0" --prefix="$LR_HOME_DIR"
else
  ./configure --with-lua="$LUA_HOME_DIR" --prefix="$LR_HOME_DIR"
fi

make build
make install

ln -sf $LR_HOME_DIR/bin/luarocks $HOME/.lua/luarocks

popd
luarocks --version
