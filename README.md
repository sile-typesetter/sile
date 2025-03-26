[![Actions Build Status](https://img.shields.io/github/actions/workflow/status/sile-typesetter/sile/build.yml?branch=master&label=Linux%20Build&logo=Github)](https://github.com/sile-typesetter/sile/actions?workflow=Build)
[![Cirrus Build Status](https://img.shields.io/cirrus/github/sile-typesetter/sile?label=FreeBSD%20Build&logo=freebsd)](https://cirrus-ci.com/github/sile-typesetter/sile/master)
[![Docker Build Status](https://img.shields.io/github/actions/workflow/status/sile-typesetter/sile/deploy.yml?branch=master&label=Docker%20Build&logo=Docker)](https://github.com/sile-typesetter/sile/pkgs/container/sile)
[![Azure Build Status](https://img.shields.io/azure-devops/build/sile-typesetter/069c3e31-ee59-4bd6-b395-1f1059acd8db/1?label=Windows%20Build&logo=Azuredevops)](https://dev.azure.com/sile-typesetter/sile/_build/latest?definitionId=1&branchName=master)<br />
[![Luacheck Lint Status](https://img.shields.io/github/actions/workflow/status/sile-typesetter/sile/luacheck.yml?branch=master&label=Luacheck&logo=Lua)](https://github.com/sile-typesetter/sile/actions?workflow=Luacheck)
[![Coveralls Coverage Status](https://img.shields.io/coveralls/github/sile-typesetter/sile?label=Coverage&logo=Coveralls)](https://coveralls.io/github/sile-typesetter/sile?branch=master)<br />
[![Chat on Gitter](https://img.shields.io/gitter/room/sile-typesetter/sile?color=blue&label=Chat&logo=Gitter)](https://gitter.im/sile-typesetter/sile?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-blue.svg)](https://conventionalcommits.org)
[![Commitizen Friendly](https://img.shields.io/badge/Commitizen-friendly-blue.svg)](http://commitizen.github.io/cz-cli/)

## What is SILE?

SILE is a [typesetting][typesetting] system; its job is to produce beautiful printed documents.
Conceptually, SILE is similar to [TeX][tex]—from which it borrows some concepts and algorithms—but the similarities end there.
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

The official package uses LuaJIT.
If you install LuaRocks for use with SILE via `pacman`, use the `lua51-*` variants to match LuaJIT.

#### Fedora

Fedora Linux has SILE in their official repositories. To install run:

```console
$ dnf install sile
```

Not all the fonts are not installed by default, to install them:

```console
$ dnf install sil-gentium-plus-fonts alerque-libertinus-fonts hack-fonts
```

#### OpenSUSE

OpenSUSE has official packages ready to install the usual way:

```console
$ zypper install sile
```

#### NixOS

A [Nix `sile` package][nix] is available in both the stable and unstable channels;
  the unstable channel having the latest stable SILE releases and the stable channel being frozen on NixOS releases.
You can use all the usual Nix tricks including adding SILE into a `nix shell` environment or executing it directly with `nix run`.

See additional usage notes in the [Nix section](#nix).

#### Ubuntu

A [PPA][ppa] is available for Ubuntu users with packages of SILE and all the necessary dependencies.
We introduced support starting with Bionic (18.04) and maintain packages for all Ubuntu release series since for as long as they are supported by Canonical.

```console
$ add-apt-repository ppa:sile-typesetter/sile
$ apt-get update
$ apt-get install sile
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
Users of WSL (Windows Subsystem for Linux) may use the package manager of their choice depending on the system installed, including the respective [Arch Linux](#arch-linux) or [Ubuntu](#ubuntu) packages, [Linux Brew][linuxbrew], [source](#from-source), or via [Nix][#nixos].

Some early work is present in the repository that should enable builds via CMake and Visual Studio, see discussion in [issue #567](https://github.com/sile-typesetter/sile/pull/567), but it needs a refresh for current dependencies.
Prebuilt Windows binaries are supposed to be generated by the Azure [build pipeline][azure] and may be downloaded by selecting a build, opening the Windows job, selecting the artifact link from the final stage, and using the download button next to the sile folder.

### Multi-Platform & Containers

#### Docker

Docker images are available as [siletypesetter/sile](https://hub.docker.com/repository/docker/siletypesetter/sile).
Released versions are available as tagged containers matching the release (e.g. `v0.10.0`).
Additionally the latest release will be tagged `latest`, and a `master` tag is also available with the freshest development build.

In order to be useful you need to tell the Docker run command a way to reach your source documents.
This is done by mounting your project directory inside the container.
This also gives SILE a place to write the output.
The user and group IDs of the Docker user will be automatically adjusted to match those of the directory you mounted.

You may find it easiest to do all this with an alias like this:

```console
$ alias sile='docker run -it --volume "$(pwd):/data" siletypesetter/sile:latest'
$ sile input.sil
```

One notable issue with using SILE from a Docker container is that by default it will not have access to your system’s fonts.
To work around this you can map a folder of fonts (in any organization usable by fontconfig) into the container.
This could be your system’s default font directory, your user one, a folder with project specific resources, or anything of your choosing.
You can see where fonts are found on your system using `fc-list`.
The path of your choosing from the host system should be mounted as a volume on `/fonts` inside the container like this:

```console
$ docker run -it --volume "/usr/share/fonts:/fonts" --volume "$(pwd):/data" siletypesetter/sile:latest
```

#### Nix

The `nix` package manager is available as a standalone package manager on many platforms other than NixOS including most Linux and BSD distributions, macOS, and even for Windows via WSL;
  and thus presents a viable alternative way to run SILE on most systems.

[Nix packages][nix] are available in both the stable and unstable channels.
We recommend the unstable channel because all fresh packages (including stable SILE releases) land there first and eventually trickle down to the stable channel.
You can use all the usual Nix tricks including launching a new shell with the `sile` command available or running it directly from any shell:

```console
# Launch a new shell with SILE available
$ nix shell nixpkgs/nixpkgs-unstable#sile
$ sile <arguments>

# Run SILE directly as a single command
$ nix run nixpkgs/nixpkgs-unstable#sile -- <arguments>
```

The SILE source repository is also a [Nix Flake][nix-flakes].
This means you can run any arbitrary tagged version, branch, or commit with a single command.
This is an easy way to run SILE on other platforms, but also to test other versions or run the latest development version of SILE.

```console
# Explicitly run a tagged version
$ nix run github:sile-typesetter/sile/v0.14.13 -- <arguments>

# Use the master branch HEAD that will become the next minor release
$ nix run github:sile-typesetter/sile -- <sile arguments>

# Run the develop branch HEAD that will become the next major release
$ nix run github:sile-typesetter/sile/develop -- <sile arguments>
```

### From Source

SILE source code can be downloaded from [its website][sile] or directly from [the GitHub releases page][releases].

SILE is completely programmable using the Lua programming language.
As of v0.15.0, the CLI you actually execute is a Rust binary with a Lua VM built in.
(For compatibility and demonstration purposes a pure Lua version of the CLI is still available as \code{sile-lua}.)
The Rust binary can be built based on your system's Lua sources or use its own vendored Lua sources.
All SILE's Lua code takes a lowest-common-denominator approach to Lua compatibility.
Any of Lua 5.1, 5.2, 5.3, 5.4, or LuaJIT (2.0, 2.1, or OpenResty) are fully supported.
Compiling it to match your system's Lua version has the advantage of making it easy to access system installed Lua Rocks, but this is not a requirement.

Compiling from sources will require both a Rust toolchain and Lua sources.
At runtime no Rust tooling is required, and the system Lua interpreter is not actually used.

It also relies on external libraries to access fonts and write PDF files.
Its preferred combination of libraries is [HarfBuzz][harfbuzz] and [libtexpdf][], a PDF creation library extracted from TeX.
HarfBuzz (minimum version 2.7.4) should be available from your operating system’s package manager.
For HarfBuzz to work you will also need fontconfig installed.
SILE also requires the [ICU][icu] libraries for Unicode handling.

On macOS, ICU can be installed via Homebrew:

```console
$ brew install icu4c
```

After that, you might need to set environment variables.
If you try to `brew link` and you get a series of messages including something like these two lines, you will need to run that export line to correctly set your path:

    For pkg-config to find icu4c you may need to set:
      export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig"

Optionally you may install the Lua libraries listed in the [rockspec][] to your system (using either your system’s package manager or [luarocks][] (`luarocks install --only-deps sile-dev-1.rockspec`).
By default all the required Lua libraries will be downloaded and bundled alongside the SILE the installation.
If you downloaded a source tarball these dependencies are included.
If you are using a Git clone of the source repository the build system will require `luarocks` to fetch them during build.
Note that OpenSSL development headers will be required for one of the Lua modules to compile¹.
If your system has all the required packages already you may add `--with-system-luarocks` to the `./configure` command to avoid bundling them.

¹ <sub>OpenSSL development headers are required to build *luasec*, please make sure they are setup _BEFORE_ trying to build SILE!
If you use your system’s Luarocks packages this will be done for you, otherwise make sure you can compile luasec.
You can try just this step in isolation before building SILE using `luarocks --tree=/tmp install luasec`.</sub>

If you are building from a git clone, start by running the script to setup your environment (if you are using the source tarball this is unnecessary):

```console
$ ./bootstrap.sh
```

If you just plan on installing and using SILE, the default configure options (plus any Lua related options discussed above) should be fine.
If you plan on developing SILE itself (whether to just tinker with it for your own use or contribute upstream) there is one particularly useful configuration option.
You can add `--enable-developer-mode` will set the 'installed data' directory to the source location which will enable the compiled binary to run directly from the source directory without being installed at all.
Additionally it will enable checks for tooling we expect SILE contributors to have such as tools used for testing.
Using this options also enables a number of targets that wouldn’t normally be needed by end users such as `make regressions`.

Once your dependencies are installed and you know what options you want, it is time to configure the sources, then build them.

```console
$ ./configure
$ make
```

If you just want to mess with SILE locally you can stop here (especially if you used `--enable-developer-mode`).
However to actually install, you will need to run the installation command with system permissions.

```console
$ sudo make install
```

On some systems you may also need to make the system aware of the newly installed libraries before first use:

```console
$ ldconfig
```

### Default Font

Since SILE v0.9.5, the default font has been Gentium Plus which is freely available from [SIL’s site][gentium].
(Previously we used Gentium Basic, but that’s getting harder to get hold of.)
The math package uses [Libertinus Math][libertinus] by default to render formulas.
Additionally, monospace text by default is set in [Hack][hack].
It is not absolutely required that you install default fonts, but if this font is not installed on your system you won’t be able to use the examples without modification.

### Testing the installation

If all goes well, after installation you should be able to render a sample document.
Try creating a file `test.sil` with this content:

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
Packages may be hosted anywhere, either on the default [luarocks.org](https://luarocks.org/) repository, on 3rd party repositories, or even private repositories.
Note some servers support more than one manifest, so you may need a `--server` argument to pick the right one.

Third party packages must be installed for the same version of Lua that SILE uses.
On systems with more than one Lua version installed, *and* where SILE does not use the default one you may need to specify the version manually.
In these examples, we'll ask SILE directory which version it is running.

For example, to install [markdown.sile](https://github.com/Omikhleia/markdown.sile) (a plugin that provides a SILE inputter that reads and processes Markdown documents) one could run:

```console
$ luarocks --lua-version $(sile -q <<< SILE.lua_version) install markdown.sile
```

By default, this will try to install the package to your system (the `--global` option).
This may not be desired (and usually requires root access), but there are two other places to install plugins.
First, you may add `--tree lua_modules` to install them in a directory called `lua_modules` in the current directory.
In this case (and assuming this is the same directory as your document) SILE will automatically find such plugins.

Additionally, you may install them to your user profile by adding `--local` when installing.
You may also install them to any other directory besides 'lua_modules' relative to your input files.
In these cases you will also need instruct SILE to check for plugins in your preferred path since Lua (and hence SILE) does not do so by default.
This can be done in either of two ways.
You can set an environment variable by running `eval $(luarocks --lua-version $(sile -q <<< SILE.lua_version) path --local)` (or the `--tree path` of your choice).
This can be done once per shell before running SILE or from your shell’s initialization script to make it permanent.
For a simpler incantation that needs to be typed into the SILE command on each use, you can also specify a tree by passing a `--luarocks-tree path` argument to SILE itself.

## Finding Out More

Please read the [full SILE manual][doc] for more information about what SILE is and how it can help you.
There are example documents (source and PDF) [on the SILE website][examples].
There’s also an [FAQ][faq] available.

## Contact

Please report bugs and send patches and pull requests at the [github repository][github].
For questions and discussion, please join the [mailing list][list-en].

## License Terms

SILE is distributed under the [MIT license][license].

  [alerque-arch]: https://wiki.archlinux.org/index.php/Unofficial_user_repositories#alerque
  [arch-sile]: https://archlinux.org/packages/extra/x86_64/sile/
  [aur]: https://wiki.archlinux.org/index.php/Arch_User_Repository
  [azure]: https://dev.azure.com/sile-typesetter/sile/_build?view=runs
  [brew]: http://brew.sh
  [brewfonts]: https://github.com/Homebrew/homebrew-cask-fonts
  [copr]: https://copr.fedorainfracloud.org/coprs/jonny/SILE/
  [doc]: http://sile-typesetter.org/manual/sile-latest.pdf
  [examples]: http://www.sile-typesetter.org/examples/
  [faq]: https://github.com/sile-typesetter/sile/wiki/faq
  [gentium]: http://software.sil.org/gentium/download/
  [github]: https://github.com/sile-typesetter/sile
  [hack]: https://sourcefoundry.org/hack/
  [harfbuzz]: http://www.freedesktop.org/wiki/Software/HarfBuzz/
  [icu]: http://icu-project.org
  [indesign]: https://en.wikipedia.org/wiki/Adobe_InDesign
  [libertinus]: https://github.com/alerque/libertinus
  [libtexpdf]: https://github.com/sile-typesetter/libtexpdf
  [license]: http://choosealicense.com/licenses/mit/
  [linuxbrew]: https://docs.brew.sh/Homebrew-on-Linux
  [list-en]: https://groups.google.com/d/forum/sile-users
  [luarocks]: http://luarocks.org/en/Download
  [nix-flakes]: https://wiki.nixos.org/wiki/Flakes#Installing_flakes
  [nix]: https://nixos.org/nix
  [ports]: http://ports.su/print/sile
  [ppa]: https://launchpad.net/~sile-typesetter/+archive/ubuntu/sile
  [releases]: https://github.com/sile-typesetter/sile/releases
  [rockspec]: https://github.com/sile-typesetter/sile/blob/master/sile-dev-1.rockspec
  [sile]: http://www.sile-typesetter.org/
  [tex]: https://en.wikipedia.org/wiki/TeX
  [typesetting]: https://en.wikipedia.org/wiki/Typesetting
