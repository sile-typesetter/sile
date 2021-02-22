#!/usr/bin/env sh
set -e

finder () {
    test -d "$1" || return 0
    find "$@" -type f | sort -bdi | xargs printf ' %s'
}

printf '%s' "SILEDATA ="
finder core classes languages packages -name '*.lua'
finder classes -name '*.sil'

printf '\n%s' "LUALIBRARIES ="
finder lua-libraries -name '*.lua'

printf '\n%s' "LUAMODULES ="
finder lua_modules ! -name "'*~'"

printf '\n%s' "TESTSRCS ?="
finder tests -maxdepth 1 -name '*.sil'
finder tests -maxdepth 1 -name '*.xml'

printf '\n%s' "TESTEXPECTS ?="
finder tests -maxdepth 1 -name '*.expected'

printf '\n%s' "EXAMPLESSRCS ="
finder examples -maxdepth 1 -name '*.sil'
finder examples/docbook -maxdepth 1 -name '*.xml'
