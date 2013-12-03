# Simon's Improved Layout Engine

SILE is a text formatting engine. It's sort of like TeX, except it isn't
35 years old, doesn't use idiosyncratic font and output formats, and it
isn't written in Pascal.

## Install

First you will need node.js, pango and cairo installed. You will then
need to run:

* `npm install ./pangocairo`
* `npm install .`
* `pegjs core/frameparser.pegjs core/frameparser.silejs`

(I will write a proper build step soon.)

Then you should be good to go.

Try `sile test.sil`
