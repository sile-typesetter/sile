[![Build Status](https://travis-ci.org/simoncozens/sile.svg?branch=master)](https://travis-ci.org/simoncozens/sile)

## What is SILE?

SILE is a typesetting system. Its job is to produce beautiful printed documents. It’s similar to TeX, but with some ideas borrowed from InDesign, and written with modern technologies in mind.

## What can I do with it (that I can’t do with TeX)?

First, have a look at the [show-off file][showoff]

SILE allows you to

* Produce complex document layouts using frames.

* Easily extend the typesetting system in a high-level programming language. (Lua)

* Directly process XML to PDF without the use of XSL stylesheets.

* Typeset text on a grid.

## Getting and installing

### From source

SILE can be downloaded from [its home page][sile], or directly from [the release page][releases].

SILE is written in the Lua programming language, so you will need a Lua version 5.1 installation. It also relies on external libraries to access fonts and write PDF files. Its preferred combination of libraries is [harfbuzz][] and a PDF creation library extracted from TeX. It should be possible to harfbuzz from your operating system's package manager. (For Harfbuzz to work you will also need freetype2 and fontconfig installed.) If this is not possible, SILE will attempt to use the GNOME Pango/Cairo libraries.

You also need to install the following Lua libraries using [luarocks][] (downloading luarocks if you do not already have it installed).

* `lpeg`
* `luaexpat`
* `lgi` (required for Pango-Cairo only)

Once your dependencies are installed, run

* `./configure ; make install`

(If you are running SILE from git, first run `bootstrap.sh` and then
configure and make. I don't guarantee that SILE will work from the
repository, although it probably ought to.)

This will place the SILE libraries and executable in a sensible location.

### For prepackaged distributions

* **Arch Linux** packages are available in the [AUR][aur]. Use [sile][aur-rel] for the latest stable release or [sile-git][aur-dev] for testing the latest HEAD.

### Testing

If all goes well you should be able to compile one of the sample documents like this:

    $ sile examples/test.sil
    This is SILE 0.9.2
    <examples/test.sil><examples/macros.sil>[1] [2] [3] [4] [5] [6] [7] [8] [9] [10] [11] [12] [13] [14] [15] [16] [17] [18] [19] [20] [21] [22] [23] [24] [25] [26] [27] [28]

You should now have `examples/test.pdf` ready for review.

## Finding out more

Please read the [full SILE manual][doc] for more information about what SILE is and how it can help you. There are example documents (source and PDF) in the examples/ directory. There's also an [FAQ][faq] available.

## Contact

Please report bugs and send patches and pull requests at the [github repository][github]. For questions, please contact the author, Simon Cozens <simon@simon-cozens.org>.

## License terms

SILE is distributed under the [MIT licence][license].

  [sile]: http://www.sile-typesetter.org/
  [releases]: https://github.com/simoncozens/sile/releases
  [doc]: https://raw.githubusercontent.com/simoncozens/sile/master/documentation/sile.pdf
  [github]: https://github.com/simoncozens/sile
  [license]: http://choosealicense.com/licenses/mit/
  [faq]: https://github.com/simoncozens/sile/wiki/faq
  [showoff]: https://raw.githubusercontent.com/simoncozens/sile/master/examples/showoff.pdf
  [roadmap]: https://github.com/simoncozens/sile/blob/master/ROADMAP
  [luarocks]: http://luarocks.org/en/Download
  [harfbuzz]: http://www.freedesktop.org/wiki/Software/HarfBuzz/
  [aur]: https://wiki.archlinux.org/index.php/Arch_User_Repository
  [aur-rel]: https://aur.archlinux.org/packages/sile/
  [aur-dev]: https://aur.archlinux.org/packages/sile-git/
