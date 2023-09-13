AC_DEFUN_ONCE([AX_RUST_BOILERPLATE], [

        AX_TRANSFORM_PACKAGE_NAME

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

        AC_ARG_WITH([bash-completion-dir],
                AS_HELP_STRING([--with-bash-completion-dir[=PATH]],
                        [Install the bash auto-completion script in this directory. @<:@default=yes@:>@]),
                [],
                [with_bash_completion_dir=yes])
        AM_CONDITIONAL([ENABLE_BASH_COMPLETION],[test "x$with_bash_completion_dir" != "xno"])

        AM_COND_IF([ENABLE_BASH_COMPLETION], [
                PKG_CHECK_MODULES([BASH_COMPLETION], [bash-completion >= 2.0],
                        [BASH_COMPLETION_DIR="$(pkg-config --define-variable=datadir=$datadir --variable=completionsdir bash-completion)"],
                        [BASH_COMPLETION_DIR="$datadir/bash-completion/completions"])
        ], [
                BASH_COMPLETION_DIR="$with_bash_completion_dir"
        ])
        AC_SUBST([BASH_COMPLETION_DIR])

        AC_ARG_WITH([fish-completion-dir],
                AS_HELP_STRING([--with-fish-completion-dir[=PATH]],
                        [Install the fish auto-completion script in this directory. @<:@default=yes@:>@]),
                [],
                [with_fish_completion_dir=yes])
        AM_CONDITIONAL([ENABLE_FISH_COMPLETION],[test "x$with_fish_completion_dir" != "xno"])

        AM_COND_IF([ENABLE_FISH_COMPLETION], [
                PKG_CHECK_MODULES([FISH_COMPLETION], [fish >= 3.0],
                        [FISH_COMPLETION_DIR="$(pkg-config --define-variable=datadir=$datadir --variable=completionsdir fish)"],
                        [FISH_COMPLETION_DIR="$datadir/fish/vendor_completions.d"])
        ], [
                FISH_COMPLETION_DIR="$with_fish_completion_dir"
        ])
        AC_SUBST([FISH_COMPLETION_DIR])

        AC_ARG_WITH([zsh-completion-dir],
                AS_HELP_STRING([--with-zsh-completion-dir[=PATH]],
                        [Install the zsh auto-completion script in this directory. @<:@default=yes@:>@]),
                [],
                [with_zsh_completion_dir=yes])
        AM_CONDITIONAL([ENABLE_ZSH_COMPLETION],[test "x$with_zsh_completion_dir" != "xno"])

        AM_COND_IF([ENABLE_ZSH_COMPLETION], [
                ZSH_COMPLETION_DIR="$datadir/zsh/site-functions"
        ], [
                ZSH_COMPLETION_DIR="$with_zsh_completion_dir"
        ])
        AC_SUBST([ZSH_COMPLETION_DIR])

        AC_CONFIG_FILES([build-aux/rust_boilerplate.am])

])
