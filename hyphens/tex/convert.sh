#!/bin/bash
for tex in `ls sources/*.tex`; do
   base=`basename $tex .tex`
   lua scripts/texhyph2lua.lua $base
done