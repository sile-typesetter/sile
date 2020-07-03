#!/usr/bin/env bash

# A script for setting up environment for travis-ci testing.
# Sets up Lua and Luarocks.
# LUA must be "lua5.1", "lua5.2" or "luajit".
# luajit2.0 - master v2.0
# luajit2.1 - master v2.1

set -eufo pipefail

LUAJIT_BASE="LuaJIT-2.0.4"

if [ -z "${PLATFORM:-}" ]; then
  PLATFORM=$TRAVIS_OS_NAME;
fi

if [ "$PLATFORM" == "osx" ]; then
  PLATFORM="macosx";
fi

if [ -z "$PLATFORM" ]; then
  if [ "$(uname)" == "Linux" ]; then
    PLATFORM="linux";
  else
    PLATFORM="macosx";
  fi;
fi

mkdir -p $HOME/.lua

LUAJIT="no"

if [ "$PLATFORM" == "macosx" ]; then
  if [ "$LUA" == "luajit" ]; then
    LUAJIT="yes";
  fi
  if [ "$LUA" == "luajit2.0" ]; then
    LUAJIT="yes";
  fi
  if [ "$LUA" == "luajit2.1" ]; then
    LUAJIT="yes";
  fi;
elif [ "$(expr substr $LUA 1 6)" == "luajit" ]; then
  LUAJIT="yes";
fi

mkdir -p "$LUA_HOME_DIR"

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
  if [ "$PLATFORM" == "mingw" ]; then
    LUA_DLL=$(echo "$LUA.dll" | sed 's/\.//')
    perl -i -pe "s/TO_BIN= lua luac/TO_BIN= lua.exe luac.exe $LUA_DLL/" Makefile;
  fi
  make $PLATFORM CC="gcc -std=gnu99 -fPIC"
  make INSTALL_TOP="$LUA_HOME_DIR" install;

  ln -sf $LUA_HOME_DIR/bin/lua $HOME/.lua/lua
  ln -sf $LUA_HOME_DIR/bin/luac $HOME/.lua/luac;
  if [ "$PLATFORM" == "mingw" ]; then
    ln -sf $LUA_HOME_DIR/bin/$LUA_DLL $HOME/.lua/$LUA_DLL;
  fi
fi

cd $TRAVIS_BUILD_DIR

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

cd $TRAVIS_BUILD_DIR

if [ "$PLATFORM" == "mingw" ]; then # XXX Fix version thing later
  mkdir -p ~/.luarocks/
cat > ~/.luarocks/config-5.3.lua <<EOF
variables = {}
variables.CC = "gcc"
variables.LD = "gcc"
variables.LIBFLAG = "-shared -llua"
EOF
fi

rm -rf $LUAROCKS_BASE

if [ "$LUAJIT" == "yes" ]; then
  rm -rf $LUAJIT_BASE;
elif [ "$LUA" == "lua5.1" ]; then
  rm -rf lua-5.1.5;
elif [ "$LUA" == "lua5.2" ]; then
  rm -rf lua-5.2.4;
elif [ "$LUA" == "lua5.3" ]; then
  rm -rf lua-5.3.5;
elif [ "$LUA" == "lua5.4" ]; then
  rm -rf lua-5.4.0;
fi
