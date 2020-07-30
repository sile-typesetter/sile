#!/usr/bin/env bash

set -e
set -o pipefail

finder () {
    echo -n ' '
    find "$@" -type f | sort -bdi | xargs echo -n ||:
}

echo -n "SILEDATA ="
finder core classes languages packages -name '*.lua'
finder classes -name '*.sil'

echo -ne "\nLUALIBRARIES ="
finder lua-libraries -name '*.lua'

echo -ne "\nLUAMODULES ="
finder lua_modules ! -name "'*~'"

echo -ne "\nTESTSRCS ?="
finder tests -maxdepth 1 -name '*.sil'
finder tests -maxdepth 1 -name '*.xml'

echo -ne "\nTESTEXPECTS ?="
finder tests -maxdepth 1 -name '*.expected'

echo -ne "\nEXAMPLESSRCS ="
finder examples -maxdepth 1 -name '*.sil'
finder examples/docbook -maxdepth 1 -name '*.xml'
