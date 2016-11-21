## What's new in SILE

## Version 0.9.5 (unreleased)

* ICU is now required for correct Unicode processing.

## Version 0.9.4 (2016-08-31)

Nearly 600 changes, including:

* New packages include: letter spacing, multiple line spacing methods, Japanese Ruby, font specimen generator, crop marks, font fallback, set PDF background color.

* Fixed handling of font weight and style.

* Hyphenation: Correct hyphenation of Indic scripts, words with non-alphabetic characters in them, and allow setting hyphen character and defining hyphenation exceptions.

* Relative dimensions ("1.2em") are converted to absolute dimensions at point of use, not point of declaration. So you can set linespacing to 1.2em, change font size, and it'll still work.

* Default paper size to A4.

* Changes to semantics of percent-of-page and percent-of-frame length specifications. (`width=50%` etc.)

* Much improved handling of footnotes, especially in multicolumn layouts.

* Support for: the libthai line breaking library, color fonts, querying the system font library on OS X, multiple Amharic justification conventions.

* Added explicit kern nodes.

* Changed to using Harfbuzz for the text processing pipeline; much faster, and much more accurate text shaping.

* Rewritten and more accurate bidirectional handling.

* Removed dependency on FreeType; use Harfbuzz for font metrics.

* Fixed the definition of an em. (It's not the width of a letter "m".)

and much more besides.

## Version 0.9.3 (2015-10-09)

* Support for typesetting Japanese according to the JIS X 4051 standard, both horizontally and vertically.

* Unicode line-breaking support; scripts now line-break correctly even if they don't have specific language support. Optionally uses the ICU library if installed.

* Font designers rejoice: you can now say \font[filename=...] to use uninstalled fonts.

* Pango/Cairo support is now officially deprecated. Stop using it!

* Improvements to USX Bible processing.

* Experimental support for Structured PDF generation.

* Support for Opentype kerning.

* Support for custom frame direction (e.g. "TTB-LTR" for Mongolian).

* Support for many-way parallel texts across pages or spreads.

* Line breaking support for Myanmar, Javanese and Uyghur.

* Support for boustrophedon Greek. No, really.

* Various fixes to bidirectionality, discretionary hyphens, insertions, footnotes, grid typesetting, alignment.

* Under-the-hood advancements for Harfbuzz.

## Version 0.9.2 (2015-06-03)

* New packages for: rotated content, accessing OpenType features and ligatures, alternative input of Unicode characters, PDF bookmarks and links, input transformation.

* Packages to help with typesetting chord sheets and bibles.

* Experimental packages for bibliography management, typesetting URLs, Japanese vertical typesetting, balanced columns, and best-fit page breaking.

* Support for quoted strings in the parameters to TeX-like commands.

* Language support: Many fixes to Arabic; support for Tibetan and Kannada; hyphenation for many languages; much improved bidirectional typesetting.

* Warn when frames are overfull.

* Support for older versions of autotools, for Lua 5.3 and mingw32 environments.

* Continuous integration and testing framework

* Fixes to long-standing bugs in grid support, centering, ligatures, insertions and page breaking.

* Better font handling and substitution.

* Valid PDFs will still be generated on error/interruption.

* Improved error handling and error messages.

* Many miscellaneous bug fixes.

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
