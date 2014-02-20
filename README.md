# Simon's Improved Layout Engine

SILE is a text formatting engine. It's sort of like TeX, except it isn't
35 years old, doesn't use idiosyncratic font and output formats, and it
isn't written in Pascal.

## Install

First you will need lua, pango and cairo installed. You will then
need to run:

* `luarocks install stdlib lgi lpeg luaexpat inspect luaepnf luarepl`
* Currently you will need the fixed version of lgi from github: https://github.com/pavouk/lgi until 0.7.3 is released.

Then you should be good to go.

Try `sile examples/test.sil`
