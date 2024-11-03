AC_PREREQ([2.69])
AC_INIT([sile], [m4_esyscmd(build-aux/git-version-gen .tarball-version)], [caleb@alerque.com])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign tar-pax dist-zstd dist-zip no-dist-gzip color-tests subdir-objects])
AM_SILENT_RULES([yes])

# Load up re-usable m4 bits shared across Caleb's projects
QUE_GIT_VERSION
QUE_TRANSFORM_PACKAGE_NAME
QUE_DEVELOPER_MODE
QUE_DIST_CHECKSUMS

# Extend the QUE checksums feature with support for the PDF manual
SILE_DIST_CHECKSUMS

# Check for and set variables for tooling used during our build process
AC_PROG_AWK
AC_PROG_CC
AC_PROG_GREP
AC_PROG_OBJC
AC_PROG_SED
QUE_PROGVAR([cmp])
QUE_PROGVAR([find])
QUE_PROGVAR([jq])
QUE_PROGVAR([pdfinfo])
QUE_PROGVAR([sort])
QUE_PROGVAR([xargs])

# Disable ranlib to avoid it being run on our rusile.so module, already LTO
# optimized but libtool wants to relink it...
RANLIB=:

LT_PREREQ([2.2])
LT_INIT([dlopen])

AC_CANONICAL_HOST

QUE_RUST_BOILERPLATE
QUE_DOCKER_BOILERPLATE

AM_CONDITIONAL([SHARED], [test "x$enable_shared" = "xyes"])
AM_CONDITIONAL([STATIC], [test "x$enable_static" = "xyes"])

AC_ARG_ENABLE([embedded],
              AS_HELP_STRING([--enable-embedded-resources],
                             [Compile resources such as Lua module files directly into the Rust CLI binary]))
AM_CONDITIONAL([EMBEDDED_RESOURCES], [test "x$enable_embedded_resources" = "xyes"])

AC_ARG_ENABLE([font-variations],
              AS_HELP_STRING([--disable-font-variations],
                             [Disable support for OpenType variations and variable fonts that requires HarfBuzz subsetter library]))
AM_CONDITIONAL([FONT_VARIATIONS], [test "x$enable_font_variations" != "xno"])

AC_ARG_ENABLE([linklua],
              AS_HELP_STRING([--disable-linklua],
                             [Don’t link lua library with dylibs]))
AM_CONDITIONAL([LINKLUA], [test "x$enable_linklua" != "xno"])

# TODO: Refactor fontconfig check to allow Appkit/DirectWrite as alternatives, maybe default to off on Darwin
# AC_ARG_WITH([fontconfig],
#             AS_HELP_STRING([--without-fontconfig],
#                            [Compile without fontconfig font manager support]))
AM_CONDITIONAL([FONTCONFIG], [test "x$with_fontconfig" != "xno"])

AC_ARG_WITH([harfbuzz],
            AS_HELP_STRING([--without-harfbuzz],
                           [Compile without HarfBuzz support used as default shaping backend]))
AM_CONDITIONAL([HARFBUZZ], [test "x$with_harfbuzz" != "xno"])

AC_ARG_WITH([system-libtexpdf],
            AS_HELP_STRING([--with-system-libtexpdf],
                           [Don’t bundle libtexpdf, use system provided version]))
AM_CONDITIONAL([SYSTEM_LIBTEXPDF], [test "x$with_system_libtexpdf" = "xyes"])

AC_ARG_WITH([system-luarocks],
            AS_HELP_STRING([--with-system-luarocks],
                           [Don’t bundle LuaRocks, use system provided versions]))
AM_CONDITIONAL([SYSTEM_LUAROCKS], [test "x$with_system_luarocks" = "xyes"])
AC_SUBST([SYSTEM_LUAROCKS])

AC_ARG_WITH([system-lua-sources],
            AS_HELP_STRING([--with-system-lua-sources],
                           [Don’t compile against vendored Lua sources, use system headers]))
AM_CONDITIONAL([SYSTEM_LUA_SOURCES], [test "x$with_system_lua_sources" = "xyes"])
AC_SUBST([SYSTEM_LUA_SOURCES])

AC_ARG_WITH([luajit],
            AS_HELP_STRING([--without-luajit],
                           [Prefer LuaJIT over PUC Lua, even if the latter is newer]))
AM_CONDITIONAL([LUAJIT], [test "x$with_luajit" != "xno"])

AC_ARG_WITH([manual],
            AS_HELP_STRING([--with-manual],
                           [Rebuild manual and install to system’s PDF documentation directory]))
AM_CONDITIONAL([MANUAL], [test "x$with_manual" = "xyes"])

AM_CONDITIONAL([FONT_DOWNLOAD_TOOLS], [test -z ${DEVELOPER_MODE_TRUE} || (test -z ${SOURCE_IS_DIST_TRUE} && test -z ${MANUAL_TRUE})])
AC_SUBST([FONT_DOWNLOAD_TOOLS])

AM_COND_IF([MANUAL], [
            QUE_PROGVAR([dot])
            QUE_PROGVAR([gs])
            ])

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
AM_CONDITIONAL([APPKIT], [test "x$have_appkit" = "xyes"])

AM_COND_IF([FONTCONFIG],
            [PKG_CHECK_MODULES(FONTCONFIG, [fontconfig],
                                [],
                                [AC_MSG_FAILURE([Fontconfig package not found])])])

AM_COND_IF([HARFBUZZ],
            [PKG_CHECK_MODULES(HARFBUZZ, [harfbuzz >= 2.7.4],
                                [],
                                [AC_MSG_FAILURE([--with-harfbuzz was given, but harfbuzz not found])]) ])

AM_COND_IF([FONT_VARIATIONS],
            [PKG_CHECK_MODULES(HARFBUZZ_SUBSET, [harfbuzz-subset >= 6.0.0],
                                [AC_DEFINE(HAVE_HARFBUZZ_SUBSET, [1], [Have harfbuzz-subset library])],
                                [AC_MSG_FAILURE([--enable-font-variations was given, but harfbuzz version not new enough to include required subset library functions])])])

AM_COND_IF([SYSTEM_LIBTEXPDF],
            [AC_CHECK_LIB([texpdf], [texpdf_doc_set_verbose],
                            [],
                            [AC_MSG_FAILURE([--with-system-libtexpdf was given, but test for libtexpdf failed])])],
            [AC_CONFIG_SUBDIRS([libtexpdf])])

PKG_CHECK_MODULES(ICU, icu-uc icu-i18n icu-io, [
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
AM_CONDITIONAL([ICU], [test "x$with_icu" = "xyes"])

# Required for downloading fonts for the manual and for tests
# Since the source tarball includes a prebuilt manual we only need this for Git source builds
AM_COND_IF([FONT_DOWNLOAD_TOOLS], [
    QUE_PROGVAR([curl])
    QUE_PROGVAR([bsdtar])
])

AM_COND_IF([DEVELOPER_MODE], [
    QUE_PROGVAR([busted])
    QUE_PROGVAR([curl])
    QUE_PROGVAR([delta])
    QUE_PROGVAR([diff])
    QUE_PROGVAR([head])
    QUE_PROGVAR([ldoc])
    QUE_PROGVAR([luacheck])
    QUE_PROGVAR([luarocks])
    QUE_PROGVAR([nix])
    QUE_PROGVAR([npm])
    QUE_PROGVAR([perl])
    QUE_PROGVAR([stylua])
    QUE_PROGVAR([tr])
    QUE_PROGVAR([typos])
])

AX_PROG_LUA([5.1])
AX_LUA_HEADERS
AX_LUA_LIBS

AM_COND_IF([SYSTEM_LUAROCKS], [
    AS_IF([test "$LUA_SHORT_VERSION" -lt 52], [
        AM_COND_IF([LUAJIT], [], [
            AX_LUA_MODULE([bit32], [bit32])
        ])
    ])
    AX_LUA_MODULE([cassowary], [cassowary])
    AS_IF([test "$LUA_SHORT_VERSION" -lt 53],
        AX_LUA_MODULE([compat53], [compat53])
    )
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
    QUE_PROGVAR([luarocks])
    QUE_PROGVAR([git]) # required for luarocks to install zlib rock
])

QUE_FONT(Gentium Plus)


AC_SUBST([APPKIT_TRUE])
AC_SUBST([FONTCONFIG_TRUE])
AC_SUBST([FONT_VARIATIONS_TRUE])
AC_SUBST([HARFBUZZ_TRUE])
AC_SUBST([HARFBUZZ_CFLAGS])
AC_SUBST([HARFBUZZ_LIBS])
AC_SUBST([HARFBUZZ_SUBSET_CFLAGS])
AC_SUBST([HARFBUZZ_SUBSET_LIBS])
AC_SUBST([ICU_TRUE])
AC_SUBST([ICU_CFLAGS])
AC_SUBST([ICU_LIBS])

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

# Avoid need for `--datarootdir=$(cd ..; pwd)` hack to run locally for
# tests/manual build when developer mode is enabled
AM_COND_IF([DEVELOPER_MODE], [
    adl_RECURSIVE_EVAL(["$(pwd)"], [SILE_PATH])
    datarootdir="$(cd ..; pwd)"
],[
    adl_RECURSIVE_EVAL(["${datadir}/${TRANSFORMED_PACKAGE_NAME}"], [SILE_PATH])
])
AC_DEFINE_UNQUOTED([SILE_PATH], ["${SILE_PATH}"], [Path for SILE packages and classes])
AC_SUBST([SILE_PATH])

# In order for our Rust CLI binary to use the same default package.path as the system Lua,
# we test the system Lua (required only at build not run time) for its current package.path.
adl_RECURSIVE_EVAL(["$(${LUA} -e 'print(package.path)')"], [SYSTEM_LUA_PATH])
AC_DEFINE_UNQUOTED([SYSTEM_LUA_PATH], ["${SYSTEM_LUA_PATH}"],[System Lua package path])
AC_SUBST([SYSTEM_LUA_PATH])

adl_RECURSIVE_EVAL(["$(${LUA} -e 'print(package.cpath)')"], [SYSTEM_LUA_CPATH])
AC_DEFINE_UNQUOTED([SYSTEM_LUA_CPATH], ["${SYSTEM_LUA_CPATH}"], [System Lua package cpath])
AC_SUBST([SYSTEM_LUA_CPATH])

adl_RECURSIVE_EVAL(["${libdir}/${TRANSFORMED_PACKAGE_NAME}"], [SILE_LIB_PATH])
AC_DEFINE_UNQUOTED([SILE_LIB_PATH],["${SILE_LIB_PATH}"], [Path for SILE libraries])
AC_SUBST([SILE_LIB_PATH])

AC_SUBST([ROCKSPECWARNING], ["DO NOT EDIT! Modify template sile.rockspec.in"])
AC_SUBST([ROCKREV], [1])

QUE_SUBST_MAN_DATE

AC_CONFIG_FILES([build-aux/list-distfiles.sh], [chmod +x build-aux/list-distfiles.sh])
AC_CONFIG_FILES([build-aux/import-tex-hyphens.sh], [chmod +x build-aux/import-tex-hyphens.sh])
AC_CONFIG_FILES([build-aux/transpile-tex-hyphen-patterns.lua], [chmod +x build-aux/transpile-tex-hyphen-patterns.lua])
AC_CONFIG_FILES([Makefile justenough/Makefile sile-lua.1 core/features.lua core/pathsetup.lua core/version.lua])
AC_CONFIG_FILES([sile-lua:sile.in], [chmod +x sile-lua])
AC_CONFIG_FILES([tests/regressions.pl], [chmod +x tests/regressions.pl])
AC_CONFIG_FILES([sile-dev-1.rockspec:sile.rockspec.in])
AC_CONFIG_FILES([src/sile-entry.sh], [chmod +x src/sile-entry.sh])

AC_OUTPUT

AC_MSG_NOTICE([monkey-patching configure to ignore core directory])
m4_esyscmd_s([build-aux/decore-automake.sh])

# Avoid the perceived need to run automake again when building from source
# tarballs. The assorted AM include macros assume two passes are needed to
# generate a makefile since one pass has to generate the includes and the
# second one inlines them, but we're distributing a ready-to-use version and
# hence one pass is enough. We can skip ahead and assume the Makefile template
# is ready to go an this point, avoiding the need for autotools at all.
AM_COND_IF([SOURCE_IS_DIST], [touch -r aminclude.am Makefile.in])
