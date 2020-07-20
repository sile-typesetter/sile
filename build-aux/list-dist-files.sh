#!/usr/bin/env bash

set -e
set -o pipefail

finder () {
    echo -n ' '
    find $@ -type f | sort | xargs echo -n ||:
}

echo -n "nobase_dist_pkgdata_DATA = \$(LUALIBRARIES)"
finder core classes languages packages -name '*.lua'
finder classes -name '*.sil'
echo -ne "\nLUALIBRARIES ="
finder lua-libraries -name '*.lua'

echo -ne "\nLUAMODULES ="
finder lua_modules ! -name "'*~'"

echo -ne "\nLUAMODULESDIST = \$(LUAMODULESDIST51) \$(LUAMODULESDIST52) \$(LUAMODULESDIST53)"
echo -ne "\nLUAMODULESDIST51 ="
finder lua_modules_dist -path '*5.1/*' ! -name "'*~'"
echo -ne "\nLUAMODULESDIST52 ="
finder lua_modules_dist -path '*5.2/*' ! -name "'*~'"
echo -ne "\nLUAMODULESDIST53 ="
finder lua_modules_dist -path '*5.3/*' ! -name "'*~'"

echo -ne "\nTESTSRCS ?="
finder tests -maxdepth 1 -name '*.sil'
finder tests -maxdepth 1 -name '*.xml'

echo -ne "\nTESTEXPECTS ?="
finder tests -maxdepth 1 -name '*.expected'

echo -ne "\nEXAMPLESSRCS ="
finder examples -maxdepth 1 -name '*.sil'
finder examples/docbook -maxdepth 1 -name '*.xml'
