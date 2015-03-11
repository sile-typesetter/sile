## What's new in SILE 

## Version 0.9.2 (unreleased)

* Rotating package (NEEDS DOC)

* Unicode character package (NEEDS DOC)

* Support for OpenType features

* Support for quoted strings in the parameters to TeX-like commands.

* Hyphenation support for many languages

* Tibetan and Kannada language support

* Restore color (and other settings) after end of scope

* Warn when frames are overfull

* Support for older versions of autotools

* Continuous integration and testing framework

* Fixes to long-standing bugs in grid support, ligatures, insertions and page breaking.

* Fixes to the ragged-left, ragged-right and centered environments.

* Experimental support for best-fit page breaking and balanced frames.

* Better font handling and substitution.

* Valid PDFs will still be generated on error/interruption.

* Improved error handling and error messages.

## Version 0.9.1 (2014-10-30)

* The main change in this release is a new shaper based on [Harfbuzz][]
  and a new PDF creation engine. This has greatly improved the output
  quality on Linux, as well as bringing support for multilingual
  typesetting and allowing future support of interesting PDF features.
  (It's also much faster.)

* The new PDF library also allows images to be embedded in many different
  formats, rather than just PNG.

* Documents can now be written in right-to-left languages such as Hebrew
  or Arabic, and it's possible to mix left-to-right and right-to-left
  text arbitrarily. (Using the Unicode Bidirectional Algorithm.)

* Initial support for languages such as Japanese which have different
  word/line breaking rules.

* Frames can be grouped into a set called a "master", and masters can
  be used to set the frame layout of a given page.

* Hopefully a much easier installation process, by bundling some of the
  required Lua modules and using the standard autoconf `./configure; make`
  strategy.

* Support for Lua 5.2.

[Harfbuzz]: http://www.freedesktop.org/wiki/Software/HarfBuzz/
