AC_DEFUN([AX_FONT], [
    AC_PROG_GREP
    if test -z "$FCMATCH"; then
        AC_PATH_PROG(FCMATCH, fc-match)
        if test -z "$FCMATCH"; then
            AC_MSG_ERROR([can't find fc-match])
        fi
    fi
    pushdef([FONT],$1)
    AC_MSG_CHECKING(whether font family FONT is available)
    AS_IF([test "$FCMATCH" = "true"],[
            AC_MSG_RESULT(skip)
    ],[
        AS_IF([$FCMATCH "FONT" family | $GREP -qx "FONT"],[
            AC_MSG_RESULT(yes)
        ],[
            AC_MSG_FAILURE([font family FONT not found])
        ])
    ])
    popdef([FONT])
])dnl
