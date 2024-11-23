AC_DEFUN([QUE_PROGVAR], [
    pushdef([VARIABLE],m4_toupper($1))
    pushdef([EXECUTABLE],m4_default($2,$1))
    AX_WITH_PROG(VARIABLE,EXECUTABLE)
    AS_IF([test "x$with_$1" != xno && test -z "$VARIABLE"], [
        AC_MSG_ERROR([EXECUTABLE is required])
    ])
    popdef([EXECUTABLE])
    popdef([VARIABLE])
])

