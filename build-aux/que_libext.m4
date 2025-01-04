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
    AM_CONDITIONAL([LIB_IS_SO], [test $LIBEXT = .so])
    AM_CONDITIONAL([LIB_IS_DYLIB], [test $LIBEXT = .dylib])
    AM_CONDITIONAL([LIB_IS_DLL], [test $LIBEXT = .dll])
    AC_SUBST([LIBEXT])
])
