# ===========================================================================
#      https://www.gnu.org/software/autoconf-archive/ax_lua_module.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_LUA_MODULE([ROCKNAME], [MODULE])
#
# DESCRIPTION
#
#   Tests the availability of a Lua module using both available mechanisms,
#   first checking if a Lua Rock manifest is available, and if not falling
#   back to attempting to load a module directly.
#
#   If the module name is the same as the rock name, the second argument can
#   be omitted.
#
#   Example usage:
#
#     AX_LUA_MODULE([ssl], [luasec])
#
#   Note: under the hood this uses AX_LUAROCKS_ROCK and AX_LUA_REQUIRE.
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

AC_DEFUN([AX_LUA_MODULE],[
    pushdef([ROCKNAME],$1)
    pushdef([MODULE],m4_default($2,$1))
    pushdef([VARIABLE],LUA_HAS_[]m4_toupper(m4_translit($1,-.,__)))

    AC_ARG_VAR(VARIABLE,Was Lua module found)

    AS_IF(test -z "$VARIABLE",[
        AX_LUAROCKS_ROCK(ROCKNAME,[VARIABLE=yes],[VARIABLE=no])
        AS_IF([test "x$VARIABLE" != xyes],[
            AX_LUA_REQUIRE(MODULE,[VARIABLE=yes])
        ])
    ])

    popdef([ROCKNAME])
    popdef([MODULE])
])
