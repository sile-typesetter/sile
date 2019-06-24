AC_PREREQ([2.68])
AC_INIT([SILE], [0.9.5.1], [simon@simon-cozens.org])
AM_INIT_AUTOMAKE([1.11.1 foreign tar-pax dist-bzip2 no-dist-gzip -Wall no-define color-tests -Wno-portability subdir-objects])
AC_CONFIG_MACRO_DIR([m4])
LT_PREREQ([2.2])
LT_INIT([dlopen])

AM_SILENT_RULES([yes])

m4_include([m4/ax_lua.m4])
m4_include([m4/adl_recursive_eval.m4])

# Checks for programs.
AC_PROG_CC_C99
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

# Checks for HB/libtexpdf combination
AC_ARG_WITH([system-libtexpdf],
    AS_HELP_STRING([--with-system-libtexpdf], [Don't build libtexpdf, use the installed version]))

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

AM_CONDITIONAL([SYSTEM_LIBTEXPDF], [test "x$with_system_libtexpdf" = "xyes"])


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

adl_RECURSIVE_EVAL(["${datadir}/${PACKAGE}"], [SILE_PATH])
AC_DEFINE_UNQUOTED([SILE_PATH],["${SILE_PATH}"],[Path for SILE packages and classes])

adl_RECURSIVE_EVAL(["${libdir}/${PACKAGE}"], [SILE_LIB_PATH])
AC_DEFINE_UNQUOTED([SILE_LIB_PATH],["${SILE_LIB_PATH}"],[Path for SILE libraries])

AM_CONDITIONAL([ICU], [test "x$with_icu" = "xyes"])
AM_CONDITIONAL([LINKLUA], [test "x$enable_linklua" != "xno"])

AC_CANONICAL_HOST
case $host_os in
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
AC_SUBST([SILE_PATH])
AC_SUBST([SILE_LIB_PATH])
AC_SUBST([shared_ext])
AC_SUBST([APPKIT])
AC_CONFIG_FILES([Makefile src/Makefile])
AC_CONFIG_FILES([sile], [chmod +x sile])

# Configure list of data files
echo 'subdir_files = \' > subfiles.mk
find core classes languages packages lua-libraries lua_modules -type f -print | sed 's/^/  /;$q;s/$/ \\/' >> subfiles.mk


AC_OUTPUT
