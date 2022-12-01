[![Actions Build Status](https://img.shields.io/github/workflow/status/sile-typesetter/sile/Build?label=Linux%20Build&logo=Github)](https://github.com/sile-typesetter/sile/actions?workflow=Build)
[![Cirrus Build Status](https://img.shields.io/cirrus/github/sile-typesetter/sile?label=FreeBSD%20Build&logo=freebsd)](https://cirrus-ci.com/github/sile-typesetter/sile/master)
[![Docker Build Status](https://img.shields.io/docker/cloud/build/siletypesetter/sile?label=Docker%20Build&logo=Docker)](https://hub.docker.com/repository/docker/siletypesetter/sile/builds)
[![Azure Build Status](https://img.shields.io/azure-devops/build/sile-typesetter/069c3e31-ee59-4bd6-b395-1f1059acd8db/1?label=Windows%20Build&logo=Azuredevops)](https://dev.azure.com/sile-typesetter/sile/_build/latest?definitionId=1&branchName=master)<br />
[![Luacheck Lint Status](https://img.shields.io/github/workflow/status/sile-typesetter/sile/Luacheck?label=Luacheck&logo=Lua)](https://github.com/sile-typesetter/sile/actions?workflow=Luacheck)
[![Coveralls Coverage Status](https://img.shields.io/coveralls/github/sile-typesetter/sile?label=Coverage&logo=Coveralls)](https://coveralls.io/github/sile-typesetter/sile?branch=master)<br />
[![Chat on Gitter](https://img.shields.io/gitter/room/simoncozens/sile?color=blue&label=Chat&logo=Gitter)](https://gitter.im/simoncozens/sile?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-blue.svg)](https://conventionalcommits.org)
[![Commitizen Friendly](https://img.shields.io/badge/Commitizen-friendly-blue.svg)](http://commitizen.github.io/cz-cli/)

## What is SILE?

SILE is a [typesetting][typesetting] system; its job is to produce beautiful printed documents.
Conceptually, SILE is similar to [TeX][tex]—from which it borrows some concepts and even syntax and algorithms—but the similarities end there.
Rather than being a derivative of the TeX family SILE is a new typesetting and layout engine written from the ground up using modern technologies and borrowing some ideas from graphical systems such as [InDesign][indesign].

## Where does it run?

SILE can be [downloaded & installed](#download-and-installation) to your system or [run remotely as a CI job](#use-as-a-CI-job).

## What can I do with SILE (that I can’t do with TeX)?

First, have a look at the [usage examples gallery][examples]. SILE allows you to:

* Produce complex document layouts using frames.

* Easily extend the typesetting system in a high-level programming language (Lua).

* Directly process XML to PDF without the use of XSL stylesheets.

* Typeset text on a grid.

## Download and Installation

### For macOS

A formula is available for [Homebrew][brew] that can install either stable or head versions.
For the latest prebuilt stable release:

```console
$ brew install sile
```

Or to build and install from the latest git commit:

```console
$ brew install sile --HEAD
```

Note the Homebrew package does not automatically install the [default font](#default-font).
The easiest way to install Gentium Plus is through the [Homebrew Fonts caskroom][brewfonts]:

```console
$ brew tap homebrew/cask-fonts
$ brew install --cask font-gentium-plus
```

### For Linux

#### Arch Linux

Arch Linux has a prebuilt [SILE package][arch-sile] in the official package repository:

```console
$ pacman -S sile
```

The official package uses Lua 5.4.
Alternatively, a package that uses LuaJIT may be built manually from the [Arch User Repository][aur] using [sile-luajit][aur-sile-luajit].
A VCS package is also available as [sile-git][aur-sile-git] to build from the latest Git commit.

#### Fedora

A [COPR][copr] repository is available for Fedora users with packages of SILE
and all the necessary dependencies including fonts.
Fedora 36 and Fedora 37 are supported.
There is work in progress to get the packages added to the official Fedora repository.

```console
$ dnf copr enable jonny/SILE
$ dnf install sile
```

#### OpenSUSE

OpenSUSE has official packages ready to install the usual way:

```console
$ zypper install sile
```

#### NixOS

A [Nix `sile` package][nix] is available in both the stable and unstable channels; the unstable channel having the latest stable SILE releases and the stable channel being frozen on NixOS releases.
You can use all the usual Nix tricks including adding SILE into a `nix shell` environment or executing it directly with `nix run`.

See additional usage notes in the [Nix section](#nix).

#### Ubuntu

A [PPA][ppa] is available for Ubuntu users with packages of SILE and all the necessary dependencies.
We introduced support starting with Bionic (18.04) and maintain packages for all Ubuntu release series since for as long as they are supported by Canonical.

```console
$ sudo add-apt-repository ppa:sile-typesetter/sile
$ sudo apt-get update
$ sudo apt-get install sile
```

#### Void Linux

Void Linux packages are available in the default package manager.

#### Other

Other Linux distros may install via [source](#from-source), via [Linux Brew][linuxbrew], or via [Nix](#nixos).

### For BSD

Install from OpenBSD [ports][], via [source](#from-source), or via [Nix](#nixos).

### For Windows

There is no installer yet (track the status in [issue #410](https://github.com/sile-typesetter/sile/issues/410)).
Nobody is currently maintaining Windows compatibility in SILE and we expect the state to be a bit broken.
Users of WSL (Windows Subsytem for Linux) may use the package manager of their choice depending on the system installed, including the respective [Arch Linux](#arch-linux) or [Ubuntu](#ubuntu) packages, [Linux Brew][linuxbrew], [source](#from-source), or via [Nix][#nixos].

Some early work is present in the repository that should enable builds via CMake and Visual Studio, see discussion in [issue #567](https://github.com/sile-typesetter/sile/pull/567), but it needs a refresh for current dependencies.
Prebuilt Windows binaries are supposed to be generated by the Azure [build pipeline][azure] and may be downloaded by selecting a build, opening the Windows job, selecting the artifact link from the final stage, and using the download button next to the sile folder.

### Multi-Platform & Containers

#### Docker

Docker images are available as [siletypesetter/sile](https://hub.docker.com/repository/docker/siletypesetter/sile).
Released versions are tagged to match (e.g. `v0.10.0`), the latest release will be tagged `latest`, and a `master` tag is also available with the freshest development build.
In order to be useful you need to tell the Docker run command a way to reach your source documents (and hence also to give it a place to write the output) as well as tell it who you are on the host machine so the output generated inside the container can be created with the expected ownership properties.
You may find it easiest to run with an alias like this:

```console
$ alias sile='docker run -it --volume "$(pwd):/data" --user "$(id -u):$(id -g)" siletypesetter/sile:latest'
$ sile input.sil
```

One notable issue with using SILE from a Docker container is that by default it will not have access to your system’s fonts.
To work around this you can map a folder of fonts (in any organization usable by fontconfig) into the container.
This could be your system’s default font directory, your user one, a folder with project specific resources, or anything of your choosing.
You can see where fonts are found on your system using `fc-list`.
The path of your choosing from the host system should be mounted as a volume on `/fonts` inside the container like this:

```console
$ docker run -it --volume "/usr/share/fonts:/fonts" --volume "$(pwd):/data" --user "$(id -u):$(id -g)" siletypesetter/sile:latest
```

#### Nix

The `nix` package manager is available as a standalone package manager on many platforms other than NixOS including most Linux and BSD distributions, macOS, and even for Windows via WSL; and thus presents a viable alternative way to run SILE on most systems.

[Nix packages][nix] are available in both the stable and unstable channels.
Because all packages are first made available in the unstable channel and then eventually make their way into the stable channel, to get the latest stable SILE releases we recommend hitting up the unstable channel first.
You can use all the usual Nix tricks including launching a new shell with the `sile` command available or running it directly from any shell:

```console
$ nix shell nixpkgs/nixpkgs-unstable#sile
$ sile <arguments>

$ nix run nixpkgs/nixpkgs-unstable#sile -- <arguments>
```

The SILE source repository is also a valid Nix [Flake][nix-flakes] which means you can run any specific version or the latest unreleased development code directly:

```console
$ nix run github:sile-typesetter/sile/v0.14.3 -- <arguments>
$ nix run github:sile-typesetter/sile -- <sile arguments>
```

### From Source

SILE source code can be downloaded from [its website][sile] or directly from [the GitHub releases page][releases].

SILE is written in the Lua programming language, so you will need a working Lua installation on your system (Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT (2.0, 2.1, or OpenResty) are fully supported).
It also relies on external libraries to access fonts and write PDF files.
Its preferred combination of libraries is [Harfbuzz][harfbuzz] and [libtexpdf][], a PDF creation library extracted from TeX. Harfbuzz (minimum version 1.1.3) should be available from your operating system's package manager.
For Harfbuzz to work you will also need fontconfig installed.
SILE also requires the [ICU][icu] libraries for Unicode handling.

On macOS, ICU can be installed via Homebrew:

```console
$ brew install icu4c
```

After that, you might need to set environment variables.
If you try to `brew link` and you get a series of messages including something like these two lines, you will need to run that export line to correctly set your path:

    For pkg-config to find icu4c you may need to set:
      export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig"

Optionally you may install the Lua libraries listed in the [rockspec][] to your system (using either your system's package manager or [luarocks][] (`luarocks install --only-deps sile-dev-1.rockspec`).
By default all the required Lua libraries will be downloaded and bundled alongside the SILE the instalation.
If you downloaded a source tarball these dependencies are included, if you are using a git clone of the source repository the build system will require `luarocks` to fetch them during build.
Note that OpenSSL development headers will be required for one of the Lua modules to compile¹.
If your system has all the required packages already you may add `--with-system-luarocks` to the `./configure` command to avoid bundling them.

¹ <sub>OpenSSL development headers are required to build *luasec*, please make sure they are setup _BEFORE_ trying to build SILE!
If you use your system’s Luarocks packages this will be done for you, otherwise make sure you can compile luasec.
You can try just this step in isolation before building SILE using `luarocks --tree=/tmp install luasec`.</sub>

If you are building from a git clone, start by running the script to setup your environment (if you are using the source tarball this is unnecessary):

```console
$ ./bootstrap.sh
```

Once your dependencies are installed, run:

```console
$ ./configure
$ make install
```

This will place the SILE libraries and executable in a sensible location.

On some systems you may also need to run:

```console
$ sudo ldconfig
```

… before trying to execute `sile` to make the system aware of the newly installed libraries.

### Default Font

Since SILE v0.9.5, the default font has been Gentium Plus which is freely available from [SIL’s site][gentium].
It is not absolutely required that you install it, but if this font is not installed on your system, you won't be able to use the examples without modification.
(Previously we used Gentium Basic, but that's getting harder to get hold of.)

### Testing the installation

If all goes well, after installation you should be able to render a sample document. Try creating a file `test.sil` with this content:

```sil
\begin{document}
Hello world!
\end{document}
```

And render it to a PDF like this:

```console
$ sile test.sil
SILE v0.12.5 (Lua 5.4)
<test.sil>
[1]
```

You should now have a PDF file `test.pdf` ready for review.

## Use as a CI job

There are actually many ways to run SILE remotely as part of a CI work flow.
Because packages are available for many platforms, one way would be to just use your platforms native package installation system to pull them into whatever CI runner environment you already use.
Another way is to pull in the prebuilt Docker container and run that.

As a case study, here is how a workflow could be setup in GitHub Actions:

```yaml
name: SILE
on: [ push, pull_request ]
jobs:
  sile:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Render document with SILE
        uses: sile-typesetter/sile@v0
        with:
          args: my-document.sil
```

Add to your repository as `.github/workflows/sile.yaml`.
This work flow assumes your project has a source file `my-document.sil` and will leave behind a `my-document.pdf`.
Note the comments in [the section about Docker](#docker) regarding version tags.

## Installing third-party packages

Third-party SILE packages can be installed using the `luarocks` package manager.
Packages may be hosted anywhere, ether on the default [luarocks.org](https://luarocks.org/) repository or (as in the example below) listed in a specific server manifest.
For example, to install [markdown.sile](https://github.com/Omikhleia/markdown.sile) (a plugin that provides a SILE inputter that reads and processes Markdown documents) one could run:

```console
$ luarocks install --server=https://luarocks.org/dev markdown.sile
```

By default, this will try to install the package to your system.
This may not be desired (and usually requires root access), but there are two other ways to install plugins.
First you make add `--tree ./` to install them in the current directory.
In this case (and assuming this is the same directory as your document) SILE will automatically find such plugins.
Additionally you make install them to your user profile by adding `--local` when installing.
In this case you will also need to modify your user environment to check for plugins in that path since Lua does not do so by default.
This can be done by running `eval $(luarocks path)` before running SILE (or from your shell's initialization script).

### Finding Lua version in use for running SILE

Third party packages must be installed for the same version of Lua that SILE uses.
On systems with more than one Lua version installed, *and* where SILE does not use the default one you may need to specify the version manually.
To get your Lua version which is used for the execution of `sile`:

```console
$ export LUA_VERSION=$(sile -e 'print(SILE.lua_version);os.exit()' 2> /dev/null)
$ luarocks install --lua-version $LUA_VERSION ...
```

## Finding Out More

Please read the [full SILE manual][doc] for more information about what SILE is and how it can help you.
There are example documents (source and PDF) [on the SILE website][examples].
There's also an [FAQ][faq] available.

## Contact

Please report bugs and send patches and pull requests at the [github repository][github].
For questions and discussion, please join the [mailing list][list-en].

日本語利用者は[メーリングリスト][list-ja]に参加してください。

## License Terms

SILE is distributed under the [MIT licence][license].

  [sile]: http://www.sile-typesetter.org/
  [releases]: https://github.com/sile-typesetter/sile/releases
  [azure]: https://dev.azure.com/sile-typesetter/sile/_build?view=runs
  [rockspec]: https://github.com/sile-typesetter/sile/blob/master/sile-dev-1.rockspec
  [doc]: http://sile-typesetter.org/manual/sile-latest.pdf
  [gentium]: http://software.sil.org/gentium/download/
  [github]: https://github.com/sile-typesetter/sile
  [license]: http://choosealicense.com/licenses/mit/
  [faq]: https://github.com/sile-typesetter/sile/wiki/faq
  [examples]: http://www.sile-typesetter.org/examples/
  [linuxbrew]: https://docs.brew.sh/Homebrew-on-Linux
  [luarocks]: http://luarocks.org/en/Download
  [harfbuzz]: http://www.freedesktop.org/wiki/Software/HarfBuzz/
  [icu]: http://icu-project.org
  [libtexpdf]: https://github.com/sile-typesetter/libtexpdf
  [arch-sile]: https://archlinux.org/packages/community/x86_64/sile/
  [aur]: https://wiki.archlinux.org/index.php/Arch_User_Repository
  [aur-sile-luajit]: https://aur.archlinux.org/packages/sile-luajit/
  [aur-sile-git]: https://aur.archlinux.org/packages/sile-git/
  [typesetting]: https://en.wikipedia.org/wiki/Typesetting
  [tex]: https://en.wikipedia.org/wiki/TeX
  [indesign]: https://en.wikipedia.org/wiki/Adobe_InDesign
  [brew]: http://brew.sh
  [brewfonts]: https://github.com/Homebrew/homebrew-cask-fonts
  [list-en]: https://groups.google.com/d/forum/sile-users
  [list-ja]: https://groups.google.com/d/forum/sile-users-ja
  [nix]: https://nixos.org/nix
  [nix-flakes]: https://nixos.wiki/wiki/Flakes#Installing_flakes
  [ports]: http://ports.su/print/sile
  [ppa]: https://launchpad.net/~sile-typesetter/+archive/ubuntu/sile
  [copr]: https://copr.fedorainfracloud.org/coprs/jonny/SILE/
  [alerque-arch]: https://wiki.archlinux.org/index.php/Unofficial_user_repositories#alerque
