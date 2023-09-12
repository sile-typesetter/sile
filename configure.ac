AC_PREREQ([2.69])
AC_INIT([sile], [m4_esyscmd(build-aux/git-version-gen .tarball-version)], [simon@simon-cozens.org])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign tar-pax dist-xz dist-zip no-dist-gzip color-tests subdir-objects])
AM_SILENT_RULES([yes])

AM_CONDITIONAL([IS_SDIST], [test ! -e .gitignore])

# Checks for programs.
AC_PROG_CC
AC_PROG_OBJC

AC_PROG_AWK
AC_PROG_GREP
AC_PROG_SED

AX_PROGVAR([cmp])
AX_PROGVAR([git])
AX_PROGVAR([find])

LT_PREREQ([2.2])
LT_INIT([dlopen])

AC_CANONICAL_HOST

AC_ARG_ENABLE(debug,
            AS_HELP_STRING([--enable-debug],[Build Rust code with debugging information [default=no]]),
            [debug_release=$enableval],
            [debug_release=no])
AM_CONDITIONAL([DEBUG_RELEASE], [test "x$debug_release" = "xyes"])

AC_ARG_ENABLE([dependency-checks],
              AS_HELP_STRING([--disable-dependency-checks],
                             [Disable dependency checks]))
AM_CONDITIONAL([DEPENDENCY_CHECKS], [test "x$enable_dependency_checks" != "xno"])

AC_ARG_ENABLE([developer],
              AS_HELP_STRING([--enable-developer],
                             [Check for and enable tooling required only for developers]))
AM_CONDITIONAL([DEVELOPER], [test "x$enable_developer" = "xyes"])

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

AC_ARG_WITH([luajit],
            AS_HELP_STRING([--with-luajit],
                           [Run under LuaJIT instead of Lua]))
AM_CONDITIONAL([LUAJIT], [test "x$with_luajit" = "xyes"])

AC_ARG_WITH([manual],
            AS_HELP_STRING([--with-manual],
                           [Rebuild manual and install to system’s PDF documentation directory]))
AM_CONDITIONAL([MANUAL], [test "x$with_manual" = "xyes"])

AM_CONDITIONAL([FONT_DOWNLOAD_TOOLS], [test -z ${DEVELOPER_TRUE} || (test -z ${MANUAL_TRUE} && test -z ${IS_SDIST_FALSE})])
AC_SUBST([FONT_DOWNLOAD_TOOLS])

AM_COND_IF([DEPENDENCY_CHECKS], [

    AX_FONT(Gentium Plus)

    AX_PROGVAR([pdfinfo])
    AX_PROGVAR([jq])
    AX_PROGVAR([xargs])
    AM_COND_IF([MANUAL], [
                AX_PROGVAR([dot])
                AX_PROGVAR([gs])
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

    PKG_CHECK_MODULES(ICU, icu-uc icu-io, [
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
        AS_IF([test "$LUA_SHORT_VERSION" -lt 52], [
            AM_COND_IF([LUAJIT], [], [
                AX_LUA_MODULE([bit32], [bit32])
            ])
        ])
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

    # Required for downloading fonts for the manual and for tests
    # Since the source tarball includes a prebuilt manual we only need this for Git source builds
    AM_COND_IF([FONT_DOWNLOAD_TOOLS], [
        AX_PROGVAR([curl])
        AX_PROGVAR([bsdtar])
    ])

    AM_COND_IF([DEVELOPER], [
        AX_PROGVAR([busted])
        AX_PROGVAR([luacheck])
        AX_PROGVAR([luarocks])
        AX_PROGVAR([nix])
        AX_PROGVAR([perl])
    ])

    AX_PROGVAR([cargo])
    AX_PROGVAR([rustc])

])

AC_MSG_CHECKING(whether to build Rust code with debugging information)
AM_COND_IF([DEBUG_RELEASE], [
    AC_MSG_RESULT(yes)
    RUST_TARGET_SUBDIR=debug
], [
    AC_MSG_RESULT(no)
    RUST_TARGET_SUBDIR=release
])
AC_SUBST([RUST_TARGET_SUBDIR])

AC_ARG_WITH([bash-completion-dir],
    AS_HELP_STRING([--with-bash-completion-dir[=PATH]],
        [Install the bash auto-completion script in this directory. @<:@default=yes@:>@]),
        [],
                        [with_bash_completion_dir=yes])
if test "x$with_bash_completion_dir" = "xyes"; then
        PKG_CHECK_MODULES([BASH_COMPLETION], [bash-completion >= 2.0],
                          [BASH_COMPLETION_DIR="`pkg-config --define-variable=datadir=$datadir --variable=completionsdir bash-completion`"],
                          [BASH_COMPLETION_DIR="$datadir/bash-completion/completions"])
        else
                BASH_COMPLETION_DIR="$with_bash_completion_dir"
fi
AC_SUBST([BASH_COMPLETION_DIR])
AM_CONDITIONAL([ENABLE_BASH_COMPLETION],[test "x$with_bash_completion_dir" != "xno"])

AC_ARG_WITH([fish-completion-dir],
            AS_HELP_STRING([--with-fish-completion-dir[=PATH]],
                           [Install the fish auto-completion script in this directory. @<:@default=yes@:>@]),
                           [],
                           [with_fish_completion_dir=yes])
if test "x$with_fish_completion_dir" = "xyes"; then
        PKG_CHECK_MODULES([FISH_COMPLETION], [fish >= 3.0],
                          [FISH_COMPLETION_DIR="`pkg-config --define-variable=datadir=$datadir --variable=completionsdir fish`"],
                          [FISH_COMPLETION_DIR="$datadir/fish/vendor_completions.d"])
        else
                FISH_COMPLETION_DIR="$with_fish_completion_dir"
fi
AC_SUBST([FISH_COMPLETION_DIR])
AM_CONDITIONAL([ENABLE_FISH_COMPLETION],[test "x$with_fish_completion_dir" != "xno"])

AC_ARG_WITH([zsh-completion-dir],
            AS_HELP_STRING([--with-zsh-completion-dir[=PATH]],
                           [Install the zsh auto-completion script in this directory. @<:@default=yes@:>@]),
                           [],
                           [with_zsh_completion_dir=yes])
if test "x$with_zsh_completion_dir" = "xyes"; then
        ZSH_COMPLETION_DIR="$datadir/zsh/site-functions"
else
        ZSH_COMPLETION_DIR="$with_zsh_completion_dir"
fi
AC_SUBST([ZSH_COMPLETION_DIR])
AM_CONDITIONAL([ENABLE_ZSH_COMPLETION],[test "x$with_zsh_completion_dir" != "xno"])

AM_CONDITIONAL([APPKIT], [test "x$have_appkit" = "xyes"])
AM_CONDITIONAL([ICU], [test "x$with_icu" = "xyes"])

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

AX_SUBST_TRANSFORMED_PACKAGE_NAME

# Avoid need for `--datarootdir=$(cd ..; pwd)` hack to run locally for
# tests/manual build when developer mode is enabled
AM_COND_IF([DEVELOPER], [
        AC_DEFINE_UNQUOTED([SILE_PATH],["$(pwd)"],[Path for SILE packages and classes])
    ],[
        adl_RECURSIVE_EVAL(["${datadir}/${TRANSFORMED_PACKAGE_NAME}"], [SILE_PATH])
        AC_DEFINE_UNQUOTED([SILE_PATH],["${SILE_PATH}"],[Path for SILE packages and classes])
])

AC_SUBST([SILE_PATH])

adl_RECURSIVE_EVAL(["${libdir}/${TRANSFORMED_PACKAGE_NAME}"], [SILE_LIB_PATH])
AC_DEFINE_UNQUOTED([SILE_LIB_PATH],["${SILE_LIB_PATH}"],[Path for SILE libraries])
AC_SUBST([SILE_LIB_PATH])

AC_SUBST([ROCKSPECWARNING], ["DO NOT EDIT! Modify template sile.rockspec.in"])
AC_SUBST([ROCKREV], [1])

AX_SUBST_MAN_DATE

AC_CONFIG_FILES([build-aux/list-dist-files.sh], [chmod +x build-aux/list-dist-files.sh])
AC_CONFIG_FILES([Makefile src/Makefile sile-lua.1 core/features.lua core/pathsetup.lua core/version.lua])
AC_CONFIG_FILES([sile-lua:sile.in tests/regressions.pl], [chmod +x sile-lua tests/regressions.pl])
AC_CONFIG_FILES([sile-dev-1.rockspec:sile.rockspec.in])

AC_ARG_PROGRAM

AC_OUTPUT

AC_MSG_NOTICE([monkey-patching configure to ignore core directory])
m4_esyscmd_s([build-aux/decore-automake.sh])
