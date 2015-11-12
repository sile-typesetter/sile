AC_PREREQ([2.68])
AC_INIT([SILE], [0.9.3], [simon@simon-cozens.org])
AM_INIT_AUTOMAKE([1.11.1 foreign tar-pax dist-bzip2 no-dist-gzip -Wall no-define color-tests -Wno-portability subdir-objects])
AC_CONFIG_MACRO_DIR([m4])
LT_PREREQ([2.2])
LT_INIT([dlopen])

m4_include([m4/ax_lua.m4])
m4_include([m4/adl_recursive_eval.m4])

# Checks for programs.
AC_PROG_CC

AC_CANONICAL_HOST

case $host_os in
  darwin* )
    AC_PROG_OBJC
    save_LIBS="$LIBS"
    LIBS="$LIBS -framework AppKit"
    AC_LANG_PUSH([Objective C])
    AC_LINK_IFELSE([AC_LANG_PROGRAM([[]],[[]])],
      have_appkit=yes
      AC_DEFINE([APPKIT], [1], [Build using AppKit])
      ],
      [have_appkit=no]
    )
    AC_LANG_POP([Objective C])
   LIBS="$save_LIBS"
esac

AM_CONDITIONAL([APPKIT], [test "x$have_appkit" = "xyes"])

# Checks for HB/libtexpdf combination

AC_ARG_WITH([harfbuzz],
        [AS_HELP_STRING([--with-harfbuzz],
          [use Harfbuzz and libtexpdf libraries @<:@default=check@:>@])],
        [],
        [with_harfbuzz=check])

AC_ARG_WITH([pangocairo],
        [AS_HELP_STRING([--with-pangocairo],
          [use Pango and Cairo libraries @<:@default=check@:>@])],
        [],
        [with_pangocairo=check])

AS_IF([test "x$with_harfbuzz" = xyes -a "x$with_pangocairo" = xyes],
    [AC_MSG_FAILURE([Build with either harfbuzz/libtexpdf or pango/cairo, not both])]
    [])

AS_IF([test "x$with_harfbuzz" != xno -a "x$with_pangocairo" != xyes],
[
PKG_CHECK_MODULES(HARFBUZZ, harfbuzz,
  [
   PKG_CHECK_MODULES(FREETYPE, freetype2,[],[AC_MSG_FAILURE([Harfbuzz found but not freetype2])])
   PKG_CHECK_MODULES(FONTCONFIG, fontconfig,[],[AC_MSG_FAILURE([Harfbuzz found but not fontconfig])])
   with_harfbuzz=yes
   backend=harfbuzz
   ],
  [if test "x$with_harfbuzz" != xcheck; then
     AC_MSG_FAILURE(
       [--with-harfbuzz was given, but test for harfbuzz failed])
   fi
  ])])

# Checks for Pango/Cairo combination
AS_IF([test "x$with_pangocairo" != xno -a "x$with_harfbuzz" != xyes],
[PKG_CHECK_MODULES(PANGO, pango,
  [PKG_CHECK_MODULES(CAIRO, cairo-pdf,
   [
    AC_DEFINE([PANGO_CAIRO], [1], [Build using pango/cairo])
    with_pangocairo=yes
    backend=pangocairo
   ],[
   PKG_CHECK_MODULES(CAIRO, cairo, [
   if test "x$with_pangocairo" != xcheck; then
     AC_MSG_FAILURE(
       [--with-pangocairo was given, but test for cairo failed])
   fi
   with_pangocairo=no
   ],[
    AC_MSG_FAILURE([Cairo has no support for PDF surfaces])
   ])
  ])
  ],
  [if test "x$with_pangocairo" != xcheck; then
     AC_MSG_FAILURE(
       [--with-pangocairo was given, but test for pango failed])
   fi
   with_pangocairo=no
  ])])

# Sanity check
AS_IF([test "$backend" = ""], [AC_MSG_FAILURE([Neither harfbuzz nor pango backend configured!])])

AX_PROG_LUA([5.1])
AX_LUA_HEADERS
AX_LUA_LIBS
# Check for Lua modules
AX_LUA_MODULE([lpeg], [lpeg])
AX_LUA_MODULE([lxp], [luaexpat])
AX_LUA_MODULE([lfs], [luafilesystem])

AS_IF([test "$backend" = "pangocairo"],
  [AX_LUA_MODULE([lgi],[lgi])],
  [AC_CONFIG_SUBDIRS([libtexpdf])]
)

PKG_CHECK_MODULES(ICU, icu-uc icu-io, [
  AC_DEFINE([ICU], [1], [Build using icu4c])
  with_icu=yes
  AC_SUBST([ICU_CFLAGS])
  AC_SUBST([ICU_LIBS])
],[
with_icu=no
])

adl_RECURSIVE_EVAL(["${datadir}/${PACKAGE}"], [SILE_PATH])
AC_DEFINE_UNQUOTED([SILE_PATH],["${SILE_PATH}"],[Path for SILE packages and classes])

adl_RECURSIVE_EVAL(["${libdir}/${PACKAGE}"], [SILE_LIB_PATH])
AC_DEFINE_UNQUOTED([SILE_LIB_PATH],["${SILE_LIB_PATH}"],[Path for SILE libraries])

AC_MSG_NOTICE([Configuring with $backend backend])
AM_CONDITIONAL([HARFBUZZLIBTEXPDF], [test "$backend" = "harfbuzz"])
AM_CONDITIONAL([ICU], [test "x$with_icu" = "xyes"])

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
AC_SUBST([backend])
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
find core classes languages packages lua-libraries -type f -print | sed 's/^/  /;$q;s/$/ \\/' >> subfiles.mk


AC_OUTPUT
