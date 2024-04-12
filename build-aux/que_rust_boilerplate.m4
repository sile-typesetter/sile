AC_DEFUN_ONCE([QUE_RUST_BOILERPLATE], [

        QUE_TRANSFORM_PACKAGE_NAME
        QUE_DEVELOPER_MODE
        QUE_SHELL_COMPLETION_DIRS

        AC_ARG_ENABLE(debug,
                AS_HELP_STRING([--enable-debug],
                        [Build Rust code with debugging information]))
        AM_CONDITIONAL([DEBUG_RELEASE], [test "x$debug_release" = "xyes"])

        AC_MSG_NOTICE([checking for tools used by automake to build Rust projects])
        AC_PROG_INSTALL
        AC_PROG_SED
        QUE_PROGVAR([cargo])
        QUE_PROGVAR([jq])
        QUE_PROGVAR([rustc])
        QUE_PROGVAR([cmp])
        QUE_PROGVAR([xargs])
        AM_COND_IF([DEVELOPER_MODE], [
                QUE_PROGVAR([git])
                QUE_PROGVAR([rustfmt])
        ])

        AC_MSG_CHECKING([whether to build Rust code with debugging information])
        AM_COND_IF([DEBUG_RELEASE], [
                AC_MSG_RESULT(yes)
                RUST_TARGET_SUBDIR=debug
        ], [
                AC_MSG_RESULT(no)
                RUST_TARGET_SUBDIR=release
        ])
        AC_SUBST([RUST_TARGET_SUBDIR])

        AC_REQUIRE([AX_AM_MACROS])
        AX_ADD_AM_MACRO([dnl
EXTRA_DIST += build-aux/que_rust_boilerplate.am

$($SED -E "s/@PACKAGE_VAR@/$PACKAGE_VAR/g;s/@PACKAGE_NAME@/$PACKAGE_NAME/g" build-aux/que_rust_boilerplate.am)
])dnl

])
