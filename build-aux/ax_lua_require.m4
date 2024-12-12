# ===========================================================================
#      https://www.gnu.org/software/autoconf-archive/ax_lua_require.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_LUA_REQUIRE([MODULE], [ACTION_IF_FOUND], [ACTION_IF_NOT_FOUND])
#
# DESCRIPTION
#
#   Tests whether Lua can load a module, fails if it is not loadable.
#
#   Example usage:
#
#     AX_LUA_REQUIRE(lpeg)
#
#   Note: this is an alternative to AX_LUAROCKS_ROCK which queries the
#   LuaRocks manifest for whether something is installed. Sometimes a proper
#   manifest is not available, and this tests whether a given module name is
#   actually loadable.
#
#   It can also be useful to test for libraries that may or may not be built
#   into Lua VMs. Builtin modules will return a success.
#
# LICENSE
#
#   Copyright (c) 2024 Caleb Maclennan <caleb@alerque.com>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved. This file is offered as-is, without any
#   warranty.

#serial 1

AC_DEFUN([AX_LUA_REQUIRE],[
    # Make sure we have a Lua interpreter
    if test -z "$LUA"; then
        AX_PROG_LUA
        if test -z "$LUA"; then
            AC_MSG_ERROR([No Lua VM set])
        fi
    fi

    AC_PREREQ([2.61])

    pushdef([MODULE],$1)
    pushdef([ACTION_IF_FOUND],$2)
    pushdef([ACTION_IF_NOT_FOUND],$3)

    AC_MSG_CHECKING([whether Lua can load module MODULE])
    AS_IF([$LUA -e 'require("MODULE")' 2>/dev/null], [
        AC_MSG_RESULT([loaded])
        ACTION_IF_FOUND
    ], [
        AC_MSG_RESULT([unable to load])
        m4_ifset([ACTION_IF_NOT_FOUND],[ACTION_IF_NOT_FOUND],
            [AC_MSG_FAILURE([cannot find Lua module MODULE])])
    ])

    popdef([MODULE])
    popdef([ACTION_IF_FOUND])
    popdef([ACTION_IF_NOT_FOUND])
])
