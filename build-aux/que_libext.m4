dnl Note: requires AC_CANONICAL_TARGET to run before AC_INIT
AC_DEFUN_ONCE([QUE_LIBEXT], [
    case $target_os in
        darwin*)
            LIBEXT=.dylib
            ;;
        cygwin*|mingw*)
            LIBEXT=.dll
            ;;
        *)
            LIBEXT=.so
        ;;
    esac
    AC_SUBST([LIBEXT])
])
