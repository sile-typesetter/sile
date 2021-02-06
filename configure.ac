AC_PREREQ([2.69])
AC_INIT([SILE],[m4_esyscmd(build-aux/git-version-gen .tarball-version)],[simon@simon-cozens.org])
AM_INIT_AUTOMAKE([1.11.1 foreign tar-pax dist-zip dist-xz no-dist-gzip -Wall no-define color-tests -Wno-portability subdir-objects])
AC_CONFIG_MACRO_DIR([m4])
LT_PREREQ([2.2])
LT_INIT([dlopen])

if [[ -d .git ]]; then
    MAN_DATE=$(git log -1 --format="%cd" --date=format:"%d %B %Y" -- sile.1.in)
else
    MAN_DATE=$(date "+%d %B %Y")
fi

AM_SILENT_RULES([yes])

# Checks for programs.
AC_PROG_CC
AC_PROG_OBJC

AC_CANONICAL_HOST

AC_MSG_CHECKING([for OS X])
have_appkit=no
case $host_os in
  darwin* )
    AC_MSG_RESULT([yes])
    AC_MSG_CHECKING([for AppKit works])

    save_LIBS="$LIBS"
    LIBS="$LIBS -framework AppKit  -fmodules"
    AC_LANG_PUSH([Objective C])
    AC_LINK_IFELSE([AC_LANG_PROGRAM([[@import AppKit;]],[[]])],
      [
      have_appkit=yes
      AC_DEFINE([APPKIT], [1], [Build using AppKit])
      AC_MSG_RESULT([yes])
      ],
      [
      have_appkit=no
      AC_MSG_RESULT([no])
      ]
    )
    AC_LANG_POP([Objective C])
   LIBS="$save_LIBS"
   ;;
  *)
    AC_MSG_RESULT([no])
    ;;
esac

AM_CONDITIONAL([APPKIT], [test "x$have_appkit" = "xyes"])

AC_ARG_WITH([system-libtexpdf],
            AS_HELP_STRING([--with-system-libtexpdf], [Don’t bundle libtexpdf, use system provided version]))
AM_CONDITIONAL([SYSTEM_LIBTEXPDF], [test "x$with_system_libtexpdf" = "xyes"])

AC_ARG_WITH([system-luarocks],
            AS_HELP_STRING([--with-system-luarocks], [Don’t bundle LuaRocks, use system provided versions]))
AM_CONDITIONAL([SYSTEM_LUAROCKS], [test "x$with_system_luarocks" = "xyes"])

AC_ARG_WITH([luajit],
            AS_HELP_STRING([--with-luajit], [Run under LuaJIT instead of Lua]))
AM_CONDITIONAL([LUAJIT], [test "x$with_luajit" = "xyes"])

AC_ARG_WITH([manual],
            AS_HELP_STRING([--with-manual], [Rebuild manual and install to system’s PDF documentation directory]))
AM_CONDITIONAL([MANUAL], [test "x$with_manual" = "xyes"])

AC_ARG_WITH([examples],
            AS_HELP_STRING([--with-examples], [Rebuild examples and install to system’s PDF documentation directory]))
AM_CONDITIONAL([EXAMPLES], [test "x$with_examples" = "xyes"])

PKG_CHECK_MODULES(HARFBUZZ, harfbuzz,
  [
   PKG_CHECK_MODULES(FREETYPE, freetype2,[],[AC_MSG_FAILURE([Harfbuzz found but not freetype2])])
   PKG_CHECK_MODULES(FONTCONFIG, fontconfig,[],[AC_MSG_FAILURE([Harfbuzz found but not fontconfig])])
   with_harfbuzz=yes
   backend=harfbuzz

   AS_IF([test "x$with_system_libtexpdf" != "xyes"],
     [
     AC_CONFIG_SUBDIRS([libtexpdf])
     ],
     [
       AC_CHECK_LIB([texpdf],[texpdf_doc_set_verbose],[],
         [AC_MSG_FAILURE([--with-system-libtexpdf was given, but test for libtexpdf failed])]
       )
     ]
   )
   ],
  [if test "x$with_harfbuzz" != xcheck; then
     AC_MSG_FAILURE(
       [--with-harfbuzz was given, but test for harfbuzz failed])
   fi
  ])

m4_include([m4/ax_lua.m4])

case $host_os in
  msys)
    LUA_VERSION=5.3 # By fiat. This is obviously not good.
    ;;
  *)
    AX_PROG_LUA([5.1])
    ;;
esac

AX_LUA_HEADERS
AX_LUA_LIBS

AS_IF([test "x$with_system_luarocks" = "xyes"], [
    AS_IF([test "$LUA_SHORT_VERSION" -lt 52],
        AX_LUA_MODULE([bit32], [bit32])
    )
    AX_LUA_MODULE([cassowary], [cassowary])
    AS_IF([test "$LUA_SHORT_VERSION" -lt 53],
        AX_LUA_MODULE([compat53], [compat53])
    )
    AX_LUA_MODULE([cosmo], [cosmo])
    AX_LUA_MODULE([linenoise], [linenoise])
    AX_LUA_MODULE([lpeg], [lpeg])
    AX_LUA_MODULE([zlib], [lua-zlib])
    AX_LUA_MODULE([cliargs], [lua_cliargs])
    AX_LUA_MODULE([epnf], [luaepnf])
    AX_LUA_MODULE([lxp], [luaexpat])
    AX_LUA_MODULE([lfs], [luafilesystem])
    AX_LUA_MODULE([repl], [luarepl])
    AX_LUA_MODULE([ssl], [luasec])
    AX_LUA_MODULE([socket], [luasocket])
    AX_LUA_MODULE([lua-utf8], [luautf8])
    AX_LUA_MODULE([pl], [penlight])
    AX_LUA_MODULE([std], [stdlib])
    AX_LUA_MODULE([vstruct], [vstruct])
], [
    AC_CHECK_PROG(HASLUAROCKS, luarocks, yes)
    test "x$HASLUAROCKS" = "xyes" || AC_MSG_ERROR([luarocks is required])
])

AC_ARG_ENABLE([linklua],
    AS_HELP_STRING([--disable-linklua], [Don't link lua library with dylibs]))

PKG_CHECK_MODULES(ICU, icu-uc icu-io, [
  AC_DEFINE([ICU], [1], [Build using icu4c])
  with_icu=yes
  AC_SUBST([ICU_CFLAGS])
  AC_SUBST([ICU_LIBS])
],[
  AC_CHECK_TOOL(ICU_CONFIG, icu-config, no)
  AC_MSG_CHECKING([for ICU by using icu-config fallback])
  if test "$ICU_CONFIG" != "no" && "$ICU_CONFIG" --version >/dev/null; then
    ICU_LIBS=`icu-config  --ldflags-libsonly --ldflags-icuio`
    ICU_CFLAGS=`icu-config --cppflags`
    with_icu=yes
    AC_MSG_RESULT([yes])
  else
    AC_MSG_FAILURE([Required ICU library not found])
  fi
])

m4_include([m4/adl_recursive_eval.m4])

adl_RECURSIVE_EVAL(["${datadir}/${PACKAGE}"], [SILE_PATH])
AC_DEFINE_UNQUOTED([SILE_PATH],["${SILE_PATH}"],[Path for SILE packages and classes])

adl_RECURSIVE_EVAL(["${libdir}/${PACKAGE}"], [SILE_LIB_PATH])
AC_DEFINE_UNQUOTED([SILE_LIB_PATH],["${SILE_LIB_PATH}"],[Path for SILE libraries])

AM_CONDITIONAL([ICU], [test "x$with_icu" = "xyes"])
AM_CONDITIONAL([LINKLUA], [test "x$enable_linklua" != "xno"])

AC_CANONICAL_HOST
case $host_os in
  darwin*)
    LUAROCKSARGS="EXPAT_DIR=/usr/local/opt/expat OPENSSL_DIR=/usr/local/opt/openssl ZLIB_DIR=/usr/local/opt/zlib"
    SHARED_LIB_EXT="so"
    ;;
  cygwin* | mingw* )
      SHARED_LIB_EXT="dll"
      ;;
  *)
      SHARED_LIB_EXT="so"
     ;;
esac
AC_SUBST([SHARED_LIB_EXT])
AC_SUBST([HARFBUZZ_CFLAGS])
AC_SUBST([HARFBUZZ_LIBS])
AC_SUBST([LUAROCKSARGS])
AC_SUBST([SILE_PATH])
AC_SUBST([SILE_LIB_PATH])
AC_SUBST([shared_ext])
AC_SUBST([SYSTEM_LUAROCKS])
AC_SUBST([APPKIT])
AC_SUBST([MAN_DATE])
AC_CONFIG_FILES([Makefile src/Makefile sile.1])
AC_CONFIG_FILES([sile], [chmod +x sile])

AC_OUTPUT
m4_esyscmd_s([build-aux/decore-automake.sh])
