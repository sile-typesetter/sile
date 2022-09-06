AC_PREREQ([2.69])
AC_INIT([sile],[m4_esyscmd(build-aux/git-version-gen .tarball-version)],[simon@simon-cozens.org])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign tar-pax dist-xz dist-zip no-dist-gzip color-tests subdir-objects])
AM_SILENT_RULES([yes])

AM_CONDITIONAL([IS_SDIST], [test ! -e .gitignore])

# Checks for programs.
AC_PROG_CC
AC_PROG_OBJC

AC_DEFUN([AX_PROGVAR], [
          test -n "$m4_toupper($1)" || { AC_PATH_PROG(m4_toupper($1), m4_default($2,$1)) }
          test -n "$m4_toupper($1)" || AC_MSG_ERROR([m4_default($2,$1) is required])
         ])

AC_PROG_AWK
AC_PROG_GREP
AC_PROG_SED

AX_PROGVAR([cmp])
AX_PROGVAR([git])

LT_PREREQ([2.2])
LT_INIT([dlopen])

DATEFMT='%d %B %Y'
AM_COND_IF([IS_SDIST],
           [
            AX_PROGVAR([date])
            AX_BUILD_DATE_EPOCH(MAN_DATE, "$DATEFMT")
           ], [
            MAN_DATE=$($GIT log -1 --format="%cd" --date=format:"$DATEFMT" -- sile.1.in)
           ])
AC_SUBST([MAN_DATE])

AC_ARG_ENABLE([dependency-checks],
              AS_HELP_STRING([--disable-dependency-checks], [Disable dependency checks]))
AM_CONDITIONAL([DEPENDENCY_CHECKS], [test "x$enable_dependency_checks" != "xno"])

AC_CANONICAL_HOST

AC_ARG_WITH([system-libtexpdf],
            AS_HELP_STRING([--with-system-libtexpdf], [Don’t bundle libtexpdf, use system provided version]))
AM_CONDITIONAL([SYSTEM_LIBTEXPDF], [test "x$with_system_libtexpdf" = "xyes"])

AC_ARG_WITH([system-luarocks],
            AS_HELP_STRING([--with-system-luarocks], [Don’t bundle LuaRocks, use system provided versions]))
AM_CONDITIONAL([SYSTEM_LUAROCKS], [test "x$with_system_luarocks" = "xyes"])
AC_SUBST([SYSTEM_LUAROCKS])

AC_ARG_WITH([luajit],
            AS_HELP_STRING([--with-luajit], [Run under LuaJIT instead of Lua]))
AM_CONDITIONAL([LUAJIT], [test "x$with_luajit" = "xyes"])

AC_ARG_WITH([manual],
            AS_HELP_STRING([--with-manual], [Rebuild manual and install to system’s PDF documentation directory]))
AM_CONDITIONAL([MANUAL], [test "x$with_manual" = "xyes"])

AM_COND_IF([SYSTEM_LIBTEXPDF],
           [AC_CHECK_LIB([texpdf],[texpdf_doc_set_verbose],
                         [],
                         [AC_MSG_FAILURE([--with-system-libtexpdf was given, but test for libtexpdf failed])]) ],
           [AC_CONFIG_SUBDIRS([libtexpdf])])

AM_COND_IF([DEPENDENCY_CHECKS], [

    AC_PATH_PROG([PDFINFO], [pdfinfo])

    AC_MSG_CHECKING([for OS X])
    have_appkit=no
    case $host_os in
        darwin*)
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
            ], [
                have_appkit=no
                AC_MSG_RESULT([no])
            ])
            AC_LANG_POP([Objective C])
            LIBS="$save_LIBS"
            ;;
        *)
            AC_MSG_RESULT([no])
            ;;
    esac

    PKG_CHECK_MODULES(HARFBUZZ, harfbuzz, [
        PKG_CHECK_MODULES(FREETYPE, freetype2,[],[AC_MSG_FAILURE([Harfbuzz found but not freetype2])])
        PKG_CHECK_MODULES(FONTCONFIG, fontconfig,[],[AC_MSG_FAILURE([Harfbuzz found but not fontconfig])])
        with_harfbuzz=yes
        backend=harfbuzz
    ], [
        if test "x$with_harfbuzz" != xcheck; then
            AC_MSG_FAILURE([--with-harfbuzz was given, but test for harfbuzz failed])
        fi
    ])

    PKG_CHECK_MODULES(ICU, icu-uc icu-io, [
    AC_DEFINE([ICU], [1], [Build using icu4c])
    with_icu=yes
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

    AM_COND_IF([SYSTEM_LUAROCKS], [
        AS_IF([test "$LUA_SHORT_VERSION" -lt 52],
            AX_LUA_MODULE([bit32], [bit32])
        )
        AX_LUA_MODULE([cassowary], [cassowary])
        AS_IF([test "$LUA_SHORT_VERSION" -lt 53],
            AX_LUA_MODULE([compat53], [compat53])
        )
        AX_LUA_MODULE([cosmo], [cosmo])
        AX_LUA_MODULE([cldr], [cldr])
        AX_LUA_MODULE([fluent], [fluent])
        AX_LUA_MODULE([linenoise], [linenoise])
        AX_LUA_MODULE([loadkit], [loadkit])
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
        AX_LUA_MODULE([vstruct], [vstruct])
    ], [
        AX_PROGVAR([luarocks])
    ])

    AM_COND_IF([MANUAL], [AX_PROGVAR([curl])])
    AM_COND_IF([MANUAL], [AX_PROGVAR([bsdtar])])

])
AC_SUBST([ICU_CFLAGS])
AC_SUBST([ICU_LIBS])

AM_CONDITIONAL([APPKIT], [test "x$have_appkit" = "xyes"])
AC_SUBST([APPKIT])

AM_CONDITIONAL([ICU], [test "x$with_icu" = "xyes"])
AC_ARG_ENABLE([linklua],
    AS_HELP_STRING([--disable-linklua], [Don’t link lua library with dylibs]))
AM_CONDITIONAL([LINKLUA], [test "x$enable_linklua" != "xno"])

AC_CANONICAL_HOST
case $host_os in
  darwin*)
    LUAROCKSARGS="EXPAT_DIR=/usr/local/opt/expat OPENSSL_DIR=/usr/local/opt/openssl ZLIB_DIR=/usr/local/opt/zlib"
    SHARED_LIB_EXT="so"
    ;;
  cygwin*|mingw*)
      SHARED_LIB_EXT="dll"
      ;;
  *)
      SHARED_LIB_EXT="so"
     ;;
esac
AC_SUBST([SHARED_LIB_EXT])
AC_SUBST([LUAROCKSARGS])

AC_SUBST([HARFBUZZ_CFLAGS])
AC_SUBST([HARFBUZZ_LIBS])
AC_SUBST([shared_ext])

sed_program_transform_name="$(printf "$program_transform_name" | $SED -e 's,$$,$,g')"
TRANSFORMED_PACKAGE_NAME="$(printf "$PACKAGE_NAME" | $SED -e "$sed_program_transform_name")"
AC_SUBST([TRANSFORMED_PACKAGE_NAME])

adl_RECURSIVE_EVAL(["${datadir}/${TRANSFORMED_PACKAGE_NAME}"], [SILE_PATH])
AC_DEFINE_UNQUOTED([SILE_PATH],["${SILE_PATH}"],[Path for SILE packages and classes])
AC_SUBST([SILE_PATH])

adl_RECURSIVE_EVAL(["${libdir}/${TRANSFORMED_PACKAGE_NAME}"], [SILE_LIB_PATH])
AC_DEFINE_UNQUOTED([SILE_LIB_PATH],["${SILE_LIB_PATH}"],[Path for SILE libraries])
AC_SUBST([SILE_LIB_PATH])


AC_CONFIG_FILES([Makefile src/Makefile sile.1 core/version.lua])
AC_CONFIG_FILES([sile], [chmod +x sile])

AC_ARG_PROGRAM

AC_OUTPUT

AC_MSG_NOTICE([monkey-patching configure to ignore core directory])
m4_esyscmd_s([build-aux/decore-automake.sh])
