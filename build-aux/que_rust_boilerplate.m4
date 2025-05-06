AC_DEFUN_ONCE([QUE_RUST_BOILERPLATE], [

        QUE_TRANSFORM_PACKAGE_NAME
        QUE_DEVELOPER_MODE
        QUE_SHELL_COMPLETION_DIRS

        AC_ARG_ENABLE(debug,
                AS_HELP_STRING([--enable-debug],
                        [Build Rust code with debugging information]))
        AM_CONDITIONAL([DEBUG_RELEASE], [test "x$enable_debug" = "xyes"])

        AC_MSG_NOTICE([checking for tools used by automake to build Rust projects])
        AC_REQUIRE([AC_PROG_INSTALL])
        AC_REQUIRE([AC_PROG_SED])
        AX_REQUIRE_PROG([cargo])
        AX_REQUIRE_PROG([jq])
        AX_REQUIRE_PROG([rustc])
        AX_REQUIRE_PROG([xargs])
        AM_COND_IF([DEVELOPER_MODE], [
                AX_REQUIRE_PROG([git])
                AX_REQUIRE_PROG([rustfmt])
        ])

        AC_ARG_VAR(CARGO_TARGET_TRIPLE, "Target triple for Rust compilations")
        if test -z "$CARGO_TARGET_TRIPLE"; then
                CARGO_TARGET_TRIPLE="$($RUSTC -vV | $SED -n 's/host: //p')"
        fi
        AC_MSG_CHECKING([whether to build Rust code with debugging information])
        AM_COND_IF([DEBUG_RELEASE], [
                AC_MSG_RESULT(yes)
                RUST_TARGET_SUBDIR=$CARGO_TARGET_TRIPLE/debug
        ], [
                AC_MSG_RESULT(no)
                RUST_TARGET_SUBDIR=$CARGO_TARGET_TRIPLE/release
        ])
        AC_SUBST([RUST_TARGET_SUBDIR])

        AC_REQUIRE([AX_AM_MACROS])
        AX_ADD_AM_MACRO([dnl
EXTRA_DIST += build-aux/que_rust_boilerplate.am

$($SED -E "s/@PACKAGE_VAR@/$PACKAGE_VAR/g;s/@PACKAGE_NAME@/$PACKAGE_NAME/g" build-aux/que_rust_boilerplate.am)
])dnl

])

AC_DEFUN([QUE_RUST_MODULE], [

        QUE_LIBEXT
        AC_REQUIRE([AX_AM_MACROS])

        AX_ADD_AM_MACRO([dnl
EXTRA_DIST += build-aux/que_rust_module.am

$($SED -E "s/@MODULE@/$1/g" build-aux/que_rust_module.am)
])dnl

])
