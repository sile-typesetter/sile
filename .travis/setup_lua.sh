#!/usr/bin/env bash

# Don't mess with it if these are already setup (as should be the case if we
# get a cache hit on Travis)
which lua && which luarocks && exit 0 ||:

set -eufo pipefail

LUAJIT_BASE="LuaJIT-2.0.4"
PLATFORM="linux"

mkdir -p $HOME/.lua

LUAJIT="no"

if [ "$(expr substr $LUA 1 6)" == "luajit" ]; then
  LUAJIT="yes";
fi

mkdir -p "$LUA_HOME_DIR"

mkdir -p $HOME/.setup_lua
cd $HOME/.setup_lua

if [ "$LUAJIT" == "yes" ]; then

  if [ "$LUA" == "luajit" ]; then
    curl https://luajit.org/download/$LUAJIT_BASE.tar.gz | tar xz;
  else
    git clone https://luajit.org/git/luajit-2.0.git $LUAJIT_BASE;
  fi

  cd $LUAJIT_BASE

  if [ "$LUA" == "luajit2.1" ]; then
    git checkout v2.1;
    # force the INSTALL_TNAME to be luajit
    perl -i -pe 's/INSTALL_TNAME=.+/INSTALL_TNAME= luajit/' Makefile
  fi

  make && make install PREFIX="$LUA_HOME_DIR"

  ln -sf $LUA_HOME_DIR/bin/luajit $HOME/.lua/luajit
  ln -sf $LUA_HOME_DIR/bin/luajit $HOME/.lua/lua;

else

  if [ "$LUA" == "lua5.1" ]; then
    curl https://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
    cd lua-5.1.5;
  elif [ "$LUA" == "lua5.2" ]; then
    curl https://www.lua.org/ftp/lua-5.2.4.tar.gz | tar xz
    cd lua-5.2.4;
  elif [ "$LUA" == "lua5.3" ]; then
    curl https://www.lua.org/ftp/lua-5.3.5.tar.gz | tar xz
    cd lua-5.3.5;
  elif [ "$LUA" == "lua5.4" ]; then
    curl https://www.lua.org/ftp/lua-5.4.0.tar.gz | tar xz
    cd lua-5.4.0;
  fi

  # Build Lua without backwards compatibility for testing
  perl -i -pe 's/-DLUA_COMPAT_\S+//' src/Makefile
  perl -i -pe 's/-DLUA_BUILD_AS_DLL/-DLUA_USE_POSIX -DLUA_DL_DLL -DLUA_BUILD_AS_DLL/' src/Makefile
  make $PLATFORM CC="gcc -std=gnu99 -fPIC"
  make INSTALL_TOP="$LUA_HOME_DIR" install;

  ln -sf $LUA_HOME_DIR/bin/lua $HOME/.lua/lua
  ln -sf $LUA_HOME_DIR/bin/luac $HOME/.lua/luac;
fi

cd $HOME/.setup_lua

lua -v

LUAROCKS_BASE=luarocks-$LUAROCKS

curl --location https://luarocks.org/releases/$LUAROCKS_BASE.tar.gz | tar xz

cd $LUAROCKS_BASE

if [ "$LUA" == "luajit" ]; then
  ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.0" --prefix="$LR_HOME_DIR";
elif [ "$LUA" == "luajit2.0" ]; then
  ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.0" --prefix="$LR_HOME_DIR";
elif [ "$LUA" == "luajit2.1" ]; then
  ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.1" --prefix="$LR_HOME_DIR";
else
  ./configure --with-lua="$LUA_HOME_DIR" --prefix="$LR_HOME_DIR"
fi

make build && make install

ln -sf $LR_HOME_DIR/bin/luarocks $HOME/.lua/luarocks

cd $HOME/.setup_lua

luarocks --version
