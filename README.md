[![Linux Build Status](https://travis-ci.com/sile-typesetter/sile.svg?branch=master)](https://travis-ci.com/sile-typesetter/sile)
[![Windows Build Status](https://simoncozens-github.visualstudio.com/sile/_apis/build/status/simoncozens.sile?branchName=master)](https://simoncozens-github.visualstudio.com/sile/_build/latest?definitionId=1&branchName=master)
[![Luacheck](https://github.com/sile-typesetter/sile/workflows/Luacheck/badge.svg)](https://github.com/sile-typesetter/sile/actions?workflow=Luacheck)
[![Coverage Status](https://coveralls.io/repos/github/sile-typesetter/sile/badge.svg?branch=master)](https://coveralls.io/github/sile-typesetter/sile?branch=master)
[![Join the chat](https://badges.gitter.im/simoncozens/sile.svg)](https://gitter.im/simoncozens/sile?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)

## What is SILE?

SILE is a [typesetting][typesetting] system; its job is to produce beautiful printed documents. Conceptually, SILE is similar to [TeX][tex]—from which it borrows some concepts and even syntax and algorithms—but the similarities end there. Rather than being a derivative of the TeX family SILE is a new typesetting and layout engine written from the ground up using modern technologies and borrowing some ideas from graphical systems such as [InDesign][indesign].

## What can I do with SILE (that I can’t do with TeX)?

First, have a look at the [usage examples gallery][examples]. SILE allows you to:

* Produce complex document layouts using frames.

* Easily extend the typesetting system in a high-level programming language (Lua). 

* Directly process XML to PDF without the use of XSL stylesheets.

* Typeset text on a grid.

## Download and installation

### For macOS

A formula is available for [Homebrew][brew] that can install both stable and head versions. Just run `brew install sile` for the latest stable release or `brew install sile --HEAD` to build from the latest git commit.

### For Linux (prepackaged distros)

* **Arch Linux** packages are available in the [AUR][aur] that can be installed using your prefered package manager (e.g. `yaourt -S sile`). Use [sile][aur-rel] for the latest stable release or [sile-git][aur-dev] to build from the latest git commit.

* Track the status of **Ubuntu** packages in [issue #638](https://github.com/sile-typesetter/sile/issues/638).

* **Other** Linux distros may be compiled from source or, optionally installed via [Nix][nix].

### For BSD

Install from OpenBSD ports, via source, or optionally via [Nix][nix].

### For Windows

There is no installer yet (track the status in [issue #410](https://github.com/sile-typesetter/sile/issues/638)), but prebuilt Windows binaries may be downloaded from Azure's artifacts menu after selecting the [latest  build][azure]. For tips to how to build it yourself from source using CMake and Visual Studio, see [issue #567](https://github.com/sile-typesetter/sile/pull/567).

### From source

SILE can be downloaded from [its website][sile] or directly from [the Github releases page][releases].

SILE is written in the Lua programming language, so you will need a working Lua installation on your system. It also relies on external libraries to access fonts and write PDF files. Its preferred combination of libraries is [Harfbuzz][harfbuzz] and [libtexpdf][], a PDF creation library extracted from TeX. Harfbuzz (minimum version 1.4.2) should be available from your operating system's package manager. For Harfbuzz to work you will also need fontconfig installed. SILE also requires the [ICU][icu] libraries for Unicode handling.

On macOS, ICU can be installed via Homebrew:

    $ brew install icu4c

After that, you might need to set environment variables. If you try to `brew link` and you get a series of messages including something like these two lines, you will need to run that export line to correctly set your path:

    For pkg-config to find icu4c you may need to set:
      export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig"

Optionally you may install the Lua libraries listed in the [rockspec][] to your system (using either your system's package manage or [luarocks][] (`luarocks install sile-dev-1.rockspec`). By default all the required Lua libraries will bundled alongside the SILE the instalation. If you downloaded a source tarball these depenedncies are included, if you are using a git clone of the source repository the build system will require `luarocks` to fetch them during build. Note that *openssl-devel* will be required for one of the Lua modules to compile. If your system has all the required packages already you may add `--with-system-luarocks` to the `./configure` command to skip this step.

If you are building from a a git clone, start by running the script to setup your environment (if you are using the source tarball this is unnecessary):

    $ ./bootstrap.sh

Once your dependencies are installed, run:

    $ ./configure
    $ make install

This will place the SILE libraries and executable in a sensible location.

On some systems you may also need to run:

    $ sudo ldconfig

… before trying to execute `sile` to make the system aware of the newly installed libraries.

### Default font

As of SILE 0.9.5, the default font is Gentium Plus, available from [here][gentium]. If this font is not installed on your system, you won't be able to use the examples without modification. (Previously we used Gentium Basic, but that's getting harder to get hold of.)

If you are using macOS with Homebrew, the easiest way to install Gentium Plus is through the [Homebrew Fonts caskroom][brewfonts]:

    $ brew tap caskroom/fonts
    $ brew cask install font-gentium-plus

### Testing

If all goes well you should be able to compile one of the sample documents like this:

    $ sile examples/test.sil
    This is SILE 0.9.2
    <examples/test.sil><examples/macros.sil>[1] [2] [3] [4] [5] [6] [7] [8] [9] [10] [11] [12] [13] [14] [15] [16] [17] [18] [19] [20] [21] [22] [23] [24] [25] [26] [27] [28]

You should now have `examples/test.pdf` ready for review.

## Finding out more

Please read the [full SILE manual][doc] for more information about what SILE is and how it can help you. There are example documents (source and PDF) in the examples/ directory. There's also an [FAQ][faq] available.

## Contact

Please report bugs and send patches and pull requests at the [github repository][github]. For questions and discussion, please join the [mailing list][list-en].

日本語利用者は[メーリングリスト][list-ja]に参加してください。

## License terms

SILE is distributed under the [MIT licence][license].

  [sile]: http://www.sile-typesetter.org/
  [releases]: https://github.com/sile-typesetter/sile/releases
  [azure]: https://simoncozens-github.visualstudio.com/sile/_build
  [rockspec]: https://github.com/sile-typesetter/sile/blob/master/sile-dev-1.rockspec
  [doc]: http://sile-typesetter.org/manual/sile-0.9.5.pdf
  [gentium]: http://software.sil.org/gentium/download/
  [github]: https://github.com/sile-typesetter/sile
  [license]: http://choosealicense.com/licenses/mit/
  [faq]: https://github.com/sile-typesetter/sile/wiki/faq
  [examples]: http://www.sile-typesetter.org/examples/
  [luarocks]: http://luarocks.org/en/Download
  [harfbuzz]: http://www.freedesktop.org/wiki/Software/HarfBuzz/
  [icu]: http://icu-project.org
  [libtexpdf]: https://github.com/sile-typesetter/libtexpdf
  [aur]: https://wiki.archlinux.org/index.php/Arch_User_Repository
  [aur-rel]: https://aur.archlinux.org/packages/sile/
  [aur-dev]: https://aur.archlinux.org/packages/sile-git/
  [typesetting]: https://en.wikipedia.org/wiki/Typesetting
  [tex]: https://en.wikipedia.org/wiki/TeX
  [indesign]: https://en.wikipedia.org/wiki/Adobe_InDesign
  [brew]: http://brew.sh
  [brewfonts]: https://github.com/Homebrew/homebrew-cask-fonts
  [list-en]: https://groups.google.com/d/forum/sile-users
  [list-ja]: https://groups.google.com/d/forum/sile-users-ja
  [nix]: https://nixos.org/nix
