#!/usr/bin/env bash

set -e
set -o pipefail

echo -n "nobase_dist_pkgdata_DATA = "
{
find core classes languages packages lua-libraries -type f -name '*.lua'
find classes -type f -name '*.sil'
} | xargs

echo -ne "\nLUAMODULES = "
find lua_modules -type f ! -name '*~' | xargs ||:

echo -ne "\nLUAMODULESDIST = "
find lua_modules_dist -type f ! -name '*~' | xargs ||:

echo -ne "\nTESTSRCS ?= "
{
find tests -maxdepth 1 -type f -name '*.sil'
find tests -maxdepth 1 -type f -name '*.xml'
} | xargs

echo -ne "\nTESTEXPECTS ?= "
find tests -maxdepth 1 -type f -name '*.expected' | xargs

echo -ne "\nEXAMPLESSRCS = "
{
find examples -maxdepth 1 -type f -name '*.sil'
find examples/docbook -maxdepth 1 -type f -name '*.xml'
} | xargs
