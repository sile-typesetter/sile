dnl =========================================================================
dnl AX_PROG_LUA([MINIMUM-VERSION], [TOO-BIG-VERSION],
dnl             [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
dnl =========================================================================
AC_DEFUN([AX_PROG_LUA],
[
  dnl Make LUA a precious variable.
  AC_ARG_VAR([LUA], [The Lua interpreter, e.g. /usr/bin/lua5.1])

  dnl Find a Lua interpreter.
  AM_COND_IF([LUAJIT],
    [_ax_lua_interpreter_list="luajit luajit-2.1.0-beta3 luajit-2.0.5 luajit-2.0.4 luajit-2.0.3"],
    [_ax_lua_interpreter_list="lua lua5.4 lua54 lua5.3 lua53 lua5.2 lua52 lua5.1 lua51 lua5.0 lua50"])

  m4_if([$1], [],
  [ dnl No version check is needed. Find any Lua interpreter.
    AS_IF([test "x$LUA" = 'x'],
      [AC_PATH_PROGS([LUA], [_ax_lua_interpreter_list], [:])])
    ax_display_LUA='lua'

    dnl At least check if this is a Lua interpreter.
    AC_MSG_CHECKING([if $LUA is a Lua interpreter])
    _AX_LUA_CHK_IS_INTRP([$LUA],
      [AC_MSG_RESULT([yes])],
      [ AC_MSG_RESULT([no])
        AC_MSG_ERROR([not a Lua interpreter])
      ])
  ],
  [ dnl A version check is needed.
    AS_IF([test "x$LUA" != 'x'],
    [ dnl Check if this is a Lua interpreter.
      AC_MSG_CHECKING([if $LUA is a Lua interpreter])
      _AX_LUA_CHK_IS_INTRP([$LUA],
        [AC_MSG_RESULT([yes])],
        [ AC_MSG_RESULT([no])
          AC_MSG_ERROR([not a Lua interpreter])
        ])
      dnl Check the version.
      m4_if([$2], [],
        [_ax_check_text="whether $LUA version >= $1"],
        [_ax_check_text="whether $LUA version >= $1, < $2"])
      AC_MSG_CHECKING([$_ax_check_text])
      _AX_LUA_CHK_VER([$LUA], [$1], [$2],
        [AC_MSG_RESULT([yes])],
        [ AC_MSG_RESULT([no])
          AC_MSG_ERROR([version is out of range for specified LUA])])
      ax_display_LUA=$LUA
    ],
    [ dnl Try each interpreter until we find one that satisfies VERSION.
      m4_if([$2], [],
        [_ax_check_text="for a Lua interpreter with version >= $1"],
        [_ax_check_text="for a Lua interpreter with version >= $1, < $2"])
      AC_CACHE_CHECK([$_ax_check_text],
        [ax_cv_pathless_LUA],
        [ for ax_cv_pathless_LUA in $_ax_lua_interpreter_list none; do
            test "x$ax_cv_pathless_LUA" = 'xnone' && break
            _AX_LUA_CHK_IS_INTRP([$ax_cv_pathless_LUA], [], [continue])
            _AX_LUA_CHK_VER([$ax_cv_pathless_LUA], [$1], [$2], [break])
          done
        ])
      dnl Set $LUA to the absolute path of $ax_cv_pathless_LUA.
      AS_IF([test "x$ax_cv_pathless_LUA" = 'xnone'],
        [LUA=':'],
        [AC_PATH_PROG([LUA], [$ax_cv_pathless_LUA])])
      ax_display_LUA=$ax_cv_pathless_LUA
    ])
  ])

  AS_IF([test "x$LUA" = 'x:'],
  [ dnl Run any user-specified action, or abort.
    m4_default([$4], [AC_MSG_ERROR([cannot find suitable Lua interpreter])])
  ],
  [ dnl Query Lua for its version number.
    AC_CACHE_CHECK([for $ax_display_LUA version], [ax_cv_lua_version],
      [ ax_cv_lua_version=`$LUA -e 'print(_VERSION:match "(%d+%.%d+)")'` ])
    AS_IF([test "x$ax_cv_lua_version" = 'x'],
      [AC_MSG_ERROR([invalid Lua version number])])
    AC_SUBST([LUA_VERSION], [$ax_cv_lua_version])
    AC_SUBST([LUA_SHORT_VERSION], [`echo "$LUA_VERSION" | $SED 's|\.||'`])

    AM_COND_IF([LUAJIT], [
      AC_CACHE_CHECK([for $ax_display_LUA jit version], [ax_cv_luajit_version],
        [ ax_cv_luajit_version=`$LUA -e 'print(jit and jit.version:match "(%d+%..+)")'` ])
      AS_IF([test "x$ax_cv_luajit_version" = 'x'],
        [AC_MSG_ERROR([invalid Lua version number])])
      AC_SUBST([LUAJIT_VERSION], [$ax_cv_luajit_version])
      AC_SUBST([LUAJIT_SHORT_VERSION], [`echo "$LUAJIT_VERSION" | $SED 's|\.|§|;s|\..*||;s|§|.|'`])
    ])

    dnl The following check is not supported:
    dnl At times (like when building shared libraries) you may want to know
    dnl which OS platform Lua thinks this is.
    AC_CACHE_CHECK([for $ax_display_LUA platform], [ax_cv_lua_platform],
      [ax_cv_lua_platform=`$LUA -e "print('unknown')"`])
    AC_SUBST([LUA_PLATFORM], [$ax_cv_lua_platform])

    dnl Use the values of $prefix and $exec_prefix for the corresponding
    dnl values of LUA_PREFIX and LUA_EXEC_PREFIX. These are made distinct
    dnl variables so they can be overridden if need be. However, the general
    dnl consensus is that you shouldn't need this ability.
    AC_SUBST([LUA_PREFIX], ['${prefix}'])
    AC_SUBST([LUA_EXEC_PREFIX], ['${exec_prefix}'])

    dnl Lua provides no way to query the script directory, and instead
    dnl provides LUA_PATH. However, we should be able to make a safe educated
    dnl guess. If the built-in search path contains a directory which is
    dnl prefixed by $prefix, then we can store scripts there. The first
    dnl matching path will be used.
    AC_CACHE_CHECK([for $ax_display_LUA script directory],
      [ax_cv_lua_luadir],
      [ AS_IF([test "x$prefix" = 'xNONE'],
          [ax_lua_prefix=$ac_default_prefix],
          [ax_lua_prefix=$prefix])

        dnl Initialize to the default path.
        ax_cv_lua_luadir="$LUA_PREFIX/share/lua/$LUA_VERSION"

        dnl Try to find a path with the prefix.
        _AX_LUA_FND_PRFX_PTH([$LUA], [$ax_lua_prefix], [package.path])
        AS_IF([test "x$ax_lua_prefixed_path" != 'x'],
        [ dnl Fix the prefix.
          _ax_strip_prefix=`echo "$ax_lua_prefix" | $SED 's|.|.|g'`
          ax_cv_lua_luadir=`echo "$ax_lua_prefixed_path" | \
            $SED "s,^$_ax_strip_prefix,$LUA_PREFIX,"`
        ])
      ])
    AC_SUBST([luadir], [$ax_cv_lua_luadir])
    AC_SUBST([pkgluadir], [\${luadir}/$PACKAGE])

    dnl Lua provides no way to query the module directory, and instead
    dnl provides LUA_PATH. However, we should be able to make a safe educated
    dnl guess. If the built-in search path contains a directory which is
    dnl prefixed by $exec_prefix, then we can store modules there. The first
    dnl matching path will be used.
    AC_CACHE_CHECK([for $ax_display_LUA module directory],
      [ax_cv_lua_luaexecdir],
      [ AS_IF([test "x$exec_prefix" = 'xNONE'],
          [ax_lua_exec_prefix=$ax_lua_prefix],
          [ax_lua_exec_prefix=$exec_prefix])

        dnl Initialize to the default path.
        ax_cv_lua_luaexecdir="$LUA_EXEC_PREFIX/lib/lua/$LUA_VERSION"

        dnl Try to find a path with the prefix.
        _AX_LUA_FND_PRFX_PTH([$LUA],
          [$ax_lua_exec_prefix], [package.cpath])
        AS_IF([test "x$ax_lua_prefixed_path" != 'x'],
        [ dnl Fix the prefix.
          _ax_strip_prefix=`echo "$ax_lua_exec_prefix" | $SED 's|.|.|g'`
          ax_cv_lua_luaexecdir=`echo "$ax_lua_prefixed_path" | \
            $SED "s,^$_ax_strip_prefix,$LUA_EXEC_PREFIX,"`
        ])
      ])
    AC_SUBST([luaexecdir], [$ax_cv_lua_luaexecdir])
    AC_SUBST([pkgluaexecdir], [\${luaexecdir}/$PACKAGE])

    dnl Run any user specified action.
    $3
  ])
])

dnl AX_WITH_LUA is now the same thing as AX_PROG_LUA.
AC_DEFUN([AX_WITH_LUA],
[
  AC_MSG_WARN([[$0 is deprecated, please use AX_PROG_LUA]])
  AX_PROG_LUA
])


dnl =========================================================================
dnl _AX_LUA_CHK_IS_INTRP(PROG, [ACTION-IF-TRUE], [ACTION-IF-FALSE])
dnl =========================================================================
AC_DEFUN([_AX_LUA_CHK_IS_INTRP],
[
  dnl Just print _VERSION because all Lua interpreters have this global.
  AS_IF([$1 -e "print('Hello ' .. _VERSION .. '!')"],
    [$2], [$3])
])


dnl =========================================================================
dnl _AX_LUA_CHK_VER(PROG, MINIMUM-VERSION, [TOO-BIG-VERSION],
dnl                 [ACTION-IF-TRUE], [ACTION-IF-FALSE])
dnl =========================================================================
AC_DEFUN([_AX_LUA_CHK_VER],
[
  AS_IF([$1 2>/dev/null -e '
        function norm (v)
          i,j=v:match "(%d+)%.(%d+)" if i then return 100 * i + j end
        end
        v, toobig=norm (_VERSION), norm "$3" or math.huge
        os.exit ((v >= norm ("$2") and v < toobig) and 0 or 1)'],
    [$4], [$5])
])

AC_DEFUN([_AX_LUAJIT_CHK_VER],
[
  AS_IF([$1 2>/dev/null -e '
    function norm (v)
    i,j=v:match "(%d+)%.(%d+)" if i then return 100 * i + j end
    end
    v, toobig=norm (jit.version), norm "$3" or math.huge
    os.exit ((v >= norm ("$2") and v < toobig) and 0 or 1)'],
    [$4], [$5])
])


dnl =========================================================================
dnl _AX_LUA_FND_PRFX_PTH(PROG, PREFIX, LUA-PATH-VARIABLE)
dnl =========================================================================
AC_DEFUN([_AX_LUA_FND_PRFX_PTH],
[
  dnl Invokes the Lua interpreter PROG to print the path variable
  dnl LUA-PATH-VARIABLE, usually package.path or package.cpath. Paths are
  dnl then matched against PREFIX. Then ax_lua_prefixed_path is set to the
  dnl shortest sub path beginning with PREFIX up to the last directory
  dnl that does not contain a '?', if any.

  ax_lua_prefixed_path=`$1 2>/dev/null -e '
    $3:gsub ("(@<:@^;@:>@+)",
      function (p)
        p = p:gsub ("%?.*$", ""):gsub ("/@<:@^/@:>@*$", "")
        if p:match ("^$2") and (not shortest or #shortest > #p) then
          shortest = p
        end
      end)
    print (shortest or "")'`
])


dnl =========================================================================
dnl AX_LUA_HEADERS([ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
dnl =========================================================================
AC_DEFUN([AX_LUA_HEADERS],
[
  dnl Check for LUA_VERSION.
  AC_MSG_CHECKING([if LUA_VERSION is defined])
  AS_IF([test "x$LUA_VERSION" != 'x'],
    [AC_MSG_RESULT([yes])],
    [ AC_MSG_RESULT([no])
      AC_MSG_ERROR([cannot check Lua headers without knowing LUA_VERSION])
    ])

  dnl Make LUA_INCLUDE a precious variable.
  AC_ARG_VAR([LUA_INCLUDE], [The Lua includes, e.g. -I/usr/include/lua5.1])

  dnl  Some default directories to search.
  AM_COND_IF([LUAJIT],
    [_ax_lua_include_list="/usr/include/luajit-$LUAJIT_VERSION /usr/include/luajit-$LUAJIT_SHORT_VERSION /usr/local/include/luajit-$LUAJIT_VERSION /usr/local/include/luajit-$LUAJIT_SHORT_VERSION"],
    [_ax_lua_include_list="/usr/include/lua$LUA_VERSION /usr/include/lua/$LUA_VERSION /usr/include/lua$LUA_SHORT_VERSION /usr/local/include/lua$LUA_VERSION /usr/local/include/lua-$LUA_VERSION /usr/local/include/lua/$LUA_VERSION /usr/local/include/lua$LUA_SHORT_VERSION"])

  dnl Try to find the headers.
  _ax_lua_saved_cppflags=$CPPFLAGS
  CPPFLAGS="$CPPFLAGS $LUA_INCLUDE"
  AC_CHECK_HEADERS([lua.h lualib.h lauxlib.h luaconf.h])
  AM_COND_IF([LUAJIT], [AC_CHECK_HEADERS([luajit.h])])
  CPPFLAGS=$_ax_lua_saved_cppflags

  dnl Try some other directories if LUA_INCLUDE was not set.
  AS_IF([test "x$LUA_INCLUDE" = 'x' &&
      test "x$ac_cv_header_lua_h" != "xyes" ||
      test "x$with_luajit" = "xyes" &&
      test "x$ac_cv_header_luajit_h" != 'xyes'],
      [ dnl Try some common include paths.
      for _ax_include_path in $_ax_lua_include_list; do
      test ! -d "$_ax_include_path" && continue

        AC_MSG_CHECKING([for Lua headers in])
        AC_MSG_RESULT([$_ax_include_path])

        AS_UNSET([ac_cv_header_lua_h])
        AS_UNSET([ac_cv_header_luajit_h])
        AS_UNSET([ac_cv_header_lualib_h])
        AS_UNSET([ac_cv_header_lauxlib_h])
        AS_UNSET([ac_cv_header_luaconf_h])

        _ax_lua_saved_cppflags=$CPPFLAGS
        CPPFLAGS="$CPPFLAGS -I$_ax_include_path"
        AC_CHECK_HEADERS([lua.h lualib.h lauxlib.h luaconf.h])
        AM_COND_IF([LUAJIT], [AC_CHECK_HEADERS([luajit.h])])
        CPPFLAGS=$_ax_lua_saved_cppflags

        AS_IF([test "x$ac_cv_header_lua_h" = 'xyes'],
          [ LUA_INCLUDE="-I$_ax_include_path"
            break
          ])
      done
    ])

  AS_IF([test "x$ac_cv_header_lua_h" = 'xyes' && test "x$cross_compiling" != 'xyes'],
    [ dnl Make a program to print LUA_VERSION defined in the header.
      dnl TODO This probably shouldn't be a runtime test.

      AC_CACHE_CHECK([for Lua header version],
        [ax_cv_lua_header_version],
        [ _ax_lua_saved_cppflags=$CPPFLAGS
          CPPFLAGS="$CPPFLAGS $LUA_INCLUDE"
          AC_RUN_IFELSE(
            [ AC_LANG_SOURCE([[
#include <lua.h>
#include <stdlib.h>
#include <stdio.h>
int main(int argc, char ** argv)
{
  if(argc > 1) printf("%s", LUA_VERSION);
  exit(EXIT_SUCCESS);
}
]])
            ],
            [ ax_cv_lua_header_version=`./conftest$EXEEXT p | \
                $SED "s|^Lua \(.*\)|\1|" | \
                $GREP -E -o "^@<:@0-9@:>@+\.@<:@0-9@:>@+"`
            ],
            [ax_cv_lua_header_version='unknown'])
          CPPFLAGS=$_ax_lua_saved_cppflags
        ])

      dnl Compare this to the previously found LUA_VERSION.
      AC_MSG_CHECKING([if Lua header version matches $LUA_VERSION])
      AS_IF([test "x$ax_cv_lua_header_version" = "x$LUA_VERSION"],
        [ AC_MSG_RESULT([yes])
          ax_header_version_match='yes'
        ],
        [ AC_MSG_RESULT([no])
          ax_header_version_match='no'
        ])
    ],
    [
        ax_header_version_match='yes'
    ])

  dnl Was LUA_INCLUDE specified?
  AS_IF([test "x$ax_header_version_match" != 'xyes' &&
         test "x$LUA_INCLUDE" != 'x'],
    [AC_MSG_ERROR([cannot find headers for specified LUA_INCLUDE])])

  dnl Test the final result and run user code.
  AS_IF([test "x$ax_header_version_match" = 'xyes'], [$1],
    [m4_default([$2], [AC_MSG_ERROR([cannot find Lua includes])])])
])

dnl AX_LUA_HEADERS_VERSION no longer exists, use AX_LUA_HEADERS.
AC_DEFUN([AX_LUA_HEADERS_VERSION],
[
  AC_MSG_WARN([[$0 is deprecated, please use AX_LUA_HEADERS]])
])


dnl =========================================================================
dnl AX_LUA_LIBS([ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
dnl =========================================================================
AC_DEFUN([AX_LUA_LIBS],
[
  dnl TODO Should this macro also check various -L flags?

  dnl Check for LUA_VERSION.
  AC_MSG_CHECKING([if LUA_VERSION is defined])
  AS_IF([test "x$LUA_VERSION" != 'x'],
    [AC_MSG_RESULT([yes])],
    [ AC_MSG_RESULT([no])
      AC_MSG_ERROR([cannot check Lua libs without knowing LUA_VERSION])
    ])

  dnl Make LUA_LIB a precious variable.
  AC_ARG_VAR([LUA_LIB], [The Lua library, e.g. -llua5.1])

  AS_IF([test "x$LUA_LIB" != 'x'],
  [ dnl Check that LUA_LIBS works.
    _ax_lua_saved_libs=$LIBS
    LIBS="$LIBS $LUA_LIB"
    AC_SEARCH_LIBS([lua_load], [],
      [_ax_found_lua_libs='yes'],
      [_ax_found_lua_libs='no'])
    LIBS=$_ax_lua_saved_libs

    dnl Check the result.
    AS_IF([test "x$_ax_found_lua_libs" != 'xyes'],
      [AC_MSG_ERROR([cannot find libs for specified LUA_LIB])])
  ],
  [ dnl First search for extra libs.
    _ax_lua_extra_libs=''

    _ax_lua_saved_libs=$LIBS
    LIBS="$LIBS $LUA_LIB"
    AC_SEARCH_LIBS([exp], [m])
    AC_SEARCH_LIBS([dlopen], [dl])
    LIBS=$_ax_lua_saved_libs

    AS_IF([test "x$ac_cv_search_exp" != 'xno' &&
           test "x$ac_cv_search_exp" != 'xnone required'],
      [_ax_lua_extra_libs="$_ax_lua_extra_libs $ac_cv_search_exp"])

    AS_IF([test "x$ac_cv_search_dlopen" != 'xno' &&
           test "x$ac_cv_search_dlopen" != 'xnone required'],
      [_ax_lua_extra_libs="$_ax_lua_extra_libs $ac_cv_search_dlopen"])

    dnl Try to find the Lua libs.
    _ax_lua_saved_libs=$LIBS
    LIBS="$LIBS $LUA_LIB"
    AM_COND_IF([LUAJIT],
        [AC_SEARCH_LIBS([lua_load],
          [luajit$LUA_VERSION luajit$LUA_SHORT_VERSION luajit-$LUA_VERSION luajit-$LUA_SHORT_VERSION luajit],
          [_ax_found_lua_libs='yes'],
          [_ax_found_lua_libs='no'],
          [$_ax_lua_extra_libs])],
        [AC_SEARCH_LIBS([lua_load],
          [lua$LUA_VERSION lua$LUA_SHORT_VERSION lua-$LUA_VERSION lua-$LUA_SHORT_VERSION lua],
          [_ax_found_lua_libs='yes'],
          [_ax_found_lua_libs='no'],
          [$_ax_lua_extra_libs])])
    LIBS=$_ax_lua_saved_libs

    AS_IF([test "x$ac_cv_search_lua_load" != 'xno' &&
           test "x$ac_cv_search_lua_load" != 'xnone required'],
      [LUA_LIB="$ac_cv_search_lua_load $_ax_lua_extra_libs"])
  ])

  dnl Test the result and run user code.
  AS_IF([test "x$_ax_found_lua_libs" = 'xyes'], [$1],
    [m4_default([$2], [AC_MSG_ERROR([cannot find Lua libs])])])
])


dnl =========================================================================
dnl AX_LUA_READLINE([ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
dnl =========================================================================
AC_DEFUN([AX_LUA_READLINE],
[
  AX_LIB_READLINE
  AS_IF([test "x$ac_cv_header_readline_readline_h" != 'x' &&
         test "x$ac_cv_header_readline_history_h" != 'x'],
    [ LUA_LIBS_CFLAGS="-DLUA_USE_READLINE $LUA_LIBS_CFLAGS"
      $1
    ],
    [$2])
])

AC_DEFUN([AX_LUA_MODULE],
[
  AC_MSG_CHECKING([for required Lua library $1])
  AS_IF([$LUA -e 'require("$1")' 2>/dev/null], [
  AC_MSG_RESULT([found])
  $3],
  [
  AC_MSG_RESULT([not found])
  m4_default([$4], [AC_MSG_ERROR([cannot find Lua library $1 - install from luarocks package $2])])])
])
