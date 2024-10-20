#serial 0

AC_DEFUN([AX_LUA_MODULE],
[
  AX_PROG_LUA([5.1], [], [], [], [prefer])
  AC_MSG_CHECKING([whether Lua can load module $1])
  AS_IF([$LUA -e 'require("$1")' 2>/dev/null], [
    AC_MSG_RESULT([loaded])
    $3
  ], [
    AC_MSG_RESULT([unable to load])
    m4_default([$4], [AC_MSG_ERROR([cannot find Lua library $1 - install from luarocks package $2])])
  ])
])

