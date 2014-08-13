# Simon's Improved Layout Engine

SILE is a text formatting engine. It's sort of like TeX, except it isn't
35 years old, doesn't use idiosyncratic font and output formats, and it
isn't written in Pascal.

## Install

First you will need lua, pango and cairo installed. You will then
need to run:

* `luarocks install stdlib lgi lpeg luaexpat inspect luaepnf luarepl cassowary`

Once your dependencies are installed, run

* `lua install.lua`

This will place the SILE libraries and executable in a sensible
location.

Try `sile examples/test.sil`

## For more information

Read the SILE manual in documentation/sile.pdf
