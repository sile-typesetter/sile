# NOTE: This file is supposed to be similar to what is in Nixpkgs, except for
# the `version`, `src` and `libtexpdf-src` attributes that are given by the
# `flake.nix`. In Nixpkgs, we don't need `libtexpdf-src` because we use
# `fetchFromGitHub` with fetchSubmodules = true;`.
{ lib
, stdenv
, version, src, libtexpdf-src
, autoreconfHook
, gitMinimal
, pkg-config
, jq
, cargo
, rustc
, rustPlatform
, makeWrapper
, poppler_utils
, harfbuzz
, icu
, fontconfig
, lua
, libiconv
, darwin
, makeFontsConf
, gentium
, runCommand
}:

let
  luaEnv = lua.withPackages(ps: with ps; [
    cassowary
    cldr
    cosmo
    fluent
    linenoise
    loadkit
    lpeg
    lua-zlib
    lua_cliargs
    luaepnf
    luaexpat
    luafilesystem
    luarepl
    luasec
    luasocket
    luautf8
    penlight
    vstruct
    # lua packages needed for testing
    busted
    luacheck
  # NOTE: Add lua packages here, to change the luaEnv also read by `flake.nix`
  ] ++ lib.optionals (lib.versionOlder lua.luaversion "5.2") [
    bit32
  ] ++ lib.optionals (lib.versionOlder lua.luaversion "5.3") [
    compat53
  ]);
in stdenv.mkDerivation (finalAttrs: {
  pname = "sile";
  inherit version src;

  preAutoreconf = ''
    # Add the libtexpdf src instead of the git submodule. (From some reason
    # without --no-preserve=mode flag, libtexpdf/ is unwriteable). As explained
    # before, in Nixpkgs, we won't need to run these commands.
    rm -rf ./libtexpdf
    cp --no-preserve=mode -r ${libtexpdf-src} ./libtexpdf/
    # pretend to be a tarball release so sile --version will not say `vUNKNOWN`.
    echo ${finalAttrs.version} > .tarball-version
  '';

  nativeBuildInputs = [
    autoreconfHook
    gitMinimal
    pkg-config
    jq
    cargo
    rustc
    rustPlatform.cargoSetupHook
    poppler_utils
    makeWrapper
  ];
  # In Nixpkgs, we don't copy the Cargo.lock file from the repo to Nixpkgs'
  # repo, but we inherit src, and specify a hash (it is a fixed output
  # derivation). `nix-update` and `nixpkgs-update` should be able to catch that
  # hash and update it as well when performing updates.
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
  };

  buildInputs = [
    luaEnv
    harfbuzz
    icu
    fontconfig
    libiconv
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.AppKit
  ];

  configureFlags = [
    "--with-system-luarocks"
    # TODO: Explain this flag
    "PDFINFO=false"
    #"--with-manual" In Nixpkgs we add this flag, here its not important enough
  ];

  postPatch = ''
    patchShebangs build-aux/*.sh
  '' + lib.optionalString stdenv.isDarwin ''
    sed -i -e 's|@import AppKit;|#import <AppKit/AppKit.h>|' src/macfonts.m
  '';

  NIX_LDFLAGS = lib.optionalString stdenv.isDarwin "-framework AppKit";

  FONTCONFIG_FILE = makeFontsConf {
    fontDirectories = [
      gentium
    ];
  };

  enableParallelBuilding = true;

  preBuild = lib.optionalString stdenv.cc.isClang ''
    substituteInPlace libtexpdf/dpxutil.c \
      --replace "ASSERT(ht && ht->table && iter);" "ASSERT(ht && iter);"
  '';

  # remove forbidden references to $TMPDIR
  preFixup = lib.optionalString stdenv.isLinux ''
    for f in "$out"/bin/*; do
      if isELF "$f"; then
        patchelf --shrink-rpath --allowed-rpath-prefixes "$NIX_STORE" "$f"
      fi
    done
  '';

  passthru = {
    # So it will be easier to inspect this environment, in comparison to others
    inherit luaEnv;
    # Copied from Makefile.am
    tests.test = lib.optionalAttrs (!(stdenv.isDarwin && stdenv.isAarch64)) (
      runCommand "${finalAttrs.pname}-test" {
          nativeBuildInputs = [ poppler_utils finalAttrs.finalPackage ];
          inherit (finalAttrs) FONTCONFIG_FILE;
      } ''
        output=$(mktemp -t selfcheck-XXXXXX.pdf)
        echo "<sile>foo</sile>" | sile -o $output -
        pdfinfo $output | grep "SILE v${finalAttrs.version}" > $out
      '');
  };

  outputs = [ "out" "doc" "man" "dev" ];

  meta = {
    description = "A typesetting system";
    longDescription = ''
      SILE is a typesetting system; its job is to produce beautiful
      printed documents. Conceptually, SILE is similar to TeX—from
      which it borrows some concepts and even syntax and
      algorithms—but the similarities end there. Rather than being a
      derivative of the TeX family SILE is a new typesetting and
      layout engine written from the ground up using modern
      technologies and borrowing some ideas from graphical systems
      such as InDesign.
    '';
    homepage = "https://sile-typesetter.org";
    # In nixpkgs we use a version specific URL for CHANGELOG.md
    changelog = "https://github.com/sile-typesetter/sile/raw/master/CHANGELOG.md";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ doronbehar alerque ];
    license = lib.licenses.mit;
  };
})
