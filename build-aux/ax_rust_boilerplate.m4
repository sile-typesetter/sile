AC_DEFUN_ONCE([AX_RUST_BOILERPLATE], [

        AX_TRANSFORM_PACKAGE_NAME
        AX_SHELL_COMPLETION_DIRS

        AC_ARG_ENABLE(debug,
                AS_HELP_STRING([--enable-debug],
                        [Build Rust code with debugging information]))
        AM_CONDITIONAL([DEBUG_RELEASE], [test "x$debug_release" = "xyes"])

        AC_ARG_ENABLE([dependency-checks],
                AS_HELP_STRING([--disable-dependency-checks],
                        [Disable build tooling dependency checks]))
        AM_CONDITIONAL([DEPENDENCY_CHECKS], [test "x$enable_dependency_checks" != "xno"])

        AC_ARG_ENABLE([developer],
                AS_HELP_STRING([--enable-developer],
                        [Check for and enable tooling required only for developers]))
        AM_CONDITIONAL([DEVELOPER], [test "x$enable_developer" = "xyes"])

        AC_MSG_NOTICE([checking for tools used by automake to build Rust projects])
        AM_COND_IF([DEPENDENCY_CHECKS], [
                AC_PROG_INSTALL
                AX_PROGVAR([cargo])
                AX_PROGVAR([jq])
                AX_PROGVAR([rustc])
                AX_PROGVAR([git])
                AX_PROGVAR([cmp])
                AX_PROGVAR([xargs])
                AM_COND_IF([DEVELOPER], [
                        AX_PROGVAR([rustfmt])
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

        AC_CONFIG_FILES([build-aux/rust_boilerplate.am])

])
