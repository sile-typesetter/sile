#!/usr/bin/env sh
set -e

finder () {
    test -d "$1" || return 0
    find "$@" -type f | sort -bdi | xargs printf ' %s'
}

printf '%s' "SILEDATA ="
finder classes core inputters languages outputters packages shapers -name '*.lua' -not -name '*_spec.lua' -not -name 'version.lua'
finder classes -name '*.sil'
finder i18n -name '*.ftl'

printf '\n%s' "LUALIBRARIES ="
finder lua-libraries -name '*.lua'

printf '\n%s' "LUAMODULES ="
finder lua_modules -not -name "'*~'"

printf '\n%s' "TESTSRCS ?="
finder tests -maxdepth 1 -name '*.sil'
finder tests -maxdepth 1 -name '*.xml'
finder tests -maxdepth 1 -name '*.lua'
finder tests -maxdepth 1 -name '*.nil'

printf '\n%s' "BUSTEDSPECS ?="
finder tests -maxdepth 1 -name '*_spec.lua'

printf '\n%s' "TESTEXPECTS ?="
finder tests -maxdepth 1 -name '*.expected'
