AC_PREREQ([2.69])
AC_INIT([SILE], [0.9.1], [simon@simon-cozens.org])
AM_INIT_AUTOMAKE([1.11.1 gnits tar-pax dist-bzip2 no-dist-gzip -Wall no-define color-tests -Wno-portability subdir-objects])
AC_CONFIG_MACRO_DIR([m4])
LT_PREREQ([2.2])
LT_INIT([dlopen])

m4_include([m4/ax_lua.m4])
m4_include([m4/ax_cxx_check_lib.m4])
m4_include([m4/adl_recursive_eval.m4])

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC

# Checks for HB/Podofo combination

AC_ARG_WITH([harfbuzzpodofo],
        [AS_HELP_STRING([--with-harfbuzzpodofo],
          [use Harfbuzz and Podofo libraries @<:@default=check@:>@])],
        [],
        [with_harfbuzzpodofo=check])

AC_ARG_WITH([pangocairo],
        [AS_HELP_STRING([--with-pangocairo],
          [use Pango and Cairo libraries @<:@default=check@:>@])],
        [],
        [with_pangocairo=check])


AS_IF([test "x$with_harfbuzzpodofo" = xyes -a "x$with_pangocairo" = xyes],
    [AC_MSG_FAILURE([Build with either harfbuzz/podofo or pango/cairo, not both])]
    [])

AS_IF([test "x$with_harfbuzzpodofo" != xno -a "x$with_pangocairo" != xyes],
[AC_CHECK_LIB([harfbuzz], [hb_shape],
  [PKG_CHECK_MODULES(HARFBUZZ, harfbuzz)
   PKG_CHECK_MODULES(FREETYPE, freetype2,[],[AC_MSG_FAILURE([Harfbuzz found but not freetype2])])
   PKG_CHECK_MODULES(FONTCONFIG, fontconfig,[],[AC_MSG_FAILURE([Harfbuzz found but not fontconfig])])
   AC_LANG_PUSH([C++])
   AX_CXX_CHECK_LIB([podofo], [PoDoFo::PdfMemDocument],[
   AC_DEFINE([HARFBUZZ_PODOFO], [1], [Build using Harfbuzz/podofo])
   with_harfbuzzpodofo=yes
   backend=harfbuzzpodofo
   ],[
   if test "x$with_harfbuzzpodofo" != xcheck; then
     AC_MSG_FAILURE(
       [--with-harfbuzzpodofo was given, but test for podofo failed])
   fi
  ], [$FONTCONFIG_LIBS $FREETYPE_LIBS -ljpeg -lpthread -lz])
   AC_LANG_POP([C++])
  ],
  [if test "x$with_harfbuzzpodofo" != xcheck; then
     AC_MSG_FAILURE(
       [--with-harfbuzzpodofo was given, but test for harfbuzz failed])
   fi
  ])])

# Checks for Pango/Cairo combination
AS_IF([test "x$with_pangocairo" != xno -a "x$with_harfbuzzpodofo" != xyes],
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
AS_IF([test "x$with_pangocairo" = xno -a "x$with_harfbuzzpodofo" = xno], [AC_MSG_FAILURE([Neither harfbuzz nor pango backend configured!])])

AX_PROG_LUA([5.1])
AX_LUA_HEADERS
# Check for Lua modules
AX_LUA_MODULE([std])
AX_LUA_MODULE([lpeg])
AX_LUA_MODULE([lxp])
AX_LUA_MODULE([epnf])
AX_LUA_MODULE([repl])
AX_LUA_MODULE([cassowary])
AX_LUA_MODULE([inspect]) # For now

AS_IF([test "$backend" = "pangocairo"],[AX_LUA_MODULE([lgi])])


adl_RECURSIVE_EVAL(["${datadir}/${PACKAGE}"], [SILE_PATH])
AC_DEFINE_UNQUOTED([SILE_PATH],["${SILE_PATH}"],[Path for SILE packages and classes])

AC_MSG_NOTICE([Configuring with $backend backend])
AM_CONDITIONAL([HARFBUZZPODOFO], [test "$backend" = "harfbuzzpodofo"])
AC_SUBST([backend])
AC_SUBST([HARFBUZZ_CFLAGS])
AC_SUBST([HARFBUZZ_LIBS])
AC_SUBST([SILE_PATH])
AC_CONFIG_FILES([Makefile src/Makefile])
AC_CONFIG_FILES([sile], [chmod +x sile])

# Configure list of data files
echo 'subdir_files = \' > subfiles.mk
find core classes languages packages -type f -print | sed 's/^/  /;$q;s/$/ \\/' >> subfiles.mk


AC_OUTPUT
