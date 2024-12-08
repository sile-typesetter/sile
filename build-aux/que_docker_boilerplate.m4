AC_DEFUN_ONCE([QUE_DOCKER_BOILERPLATE], [

        QUE_TRANSFORM_PACKAGE_NAME

        AC_MSG_NOTICE([checking for tools used by automake to build Docker projects])
        AC_REQUIRE([AC_PROG_INSTALL])
        AM_COND_IF([DEVELOPER_MODE], [
                AX_REQUIRE_PROG([docker])
        ])

        AC_REQUIRE([AX_AM_MACROS])
        AX_ADD_AM_MACRO([dnl
EXTRA_DIST += build-aux/que_docker_boilerplate.am

$($SED -E "s/@PACKAGE_VAR@/$PACKAGE_VAR/g" build-aux/que_docker_boilerplate.am)
])dnl

])
