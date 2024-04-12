AC_DEFUN_ONCE([AX_RUST_BOILERPLATE], [

        AX_TRANSFORM_PACKAGE_NAME
        AX_SHELL_COMPLETION_DIRS

        AC_ARG_ENABLE([developer],
                AS_HELP_STRING([--enable-developer],
                        [Check for and enable tooling required only for developers. Also enables debugging profile.]))
        AM_CONDITIONAL([DEVELOPER], [test "x$enable_developer" = "xyes"])

        AM_COND_IF([DEVELOPER], [enable_debug=yes ])

        AC_ARG_ENABLE(debug,
                AS_HELP_STRING([--enable-debug],
                        [Build Rust code with debugging information]))
        AM_CONDITIONAL([DEBUG_RELEASE], [test "x$enable_debug" = "xyes"])

        AC_ARG_ENABLE([dependency-checks],
                AS_HELP_STRING([--disable-dependency-checks],
                        [Disable build tooling dependency checks]))
        AM_CONDITIONAL([DEPENDENCY_CHECKS], [test "x$enable_dependency_checks" != "xno"])

        AC_MSG_NOTICE([checking for tools used by automake to build Rust projects])
        AC_PROG_INSTALL
        QUE_PROGVAR([cargo])
        QUE_PROGVAR([jq])
        QUE_PROGVAR([rustc])
        QUE_PROGVAR([cmp])
        QUE_PROGVAR([xargs])
        AM_COND_IF([DEPENDENCY_CHECKS], [
                AM_COND_IF([DEVELOPER], [
                        QUE_PROGVAR([git])
                        QUE_PROGVAR([rustfmt])
                ])
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

        AC_CONFIG_FILES([build-aux/rust_boilerplate.mk])

])
