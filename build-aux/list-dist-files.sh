#!/usr/bin/env bash

set -e
set -o pipefail

finder () {
    echo -n ' '
    find $@ -type f | sort | xargs echo -n ||:
}

echo -n "nobase_dist_pkgdata_DATA ="
finder core classes languages packages lua-libraries -name '*.lua'
finder classes -name '*.sil'

echo -ne "\nLUAMODULES ="
finder lua_modules ! -name "'*~'"

echo -ne "\nLUAMODULESDIST ="
finder lua_modules_dist ! -name "'*~'"

echo -ne "\nTESTSRCS ?="
finder tests -maxdepth 1 -name '*.sil'
finder tests -maxdepth 1 -name '*.xml'

echo -ne "\nTESTEXPECTS ?="
finder tests -maxdepth 1 -name '*.expected'

echo -ne "\nEXAMPLESSRCS ="
finder examples -maxdepth 1 -name '*.sil'
finder examples/docbook -maxdepth 1 -name '*.xml'
