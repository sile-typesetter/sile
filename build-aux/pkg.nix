# NOTE: This file is supposed to be similar to what is in Nixpkgs, except for
# the `version`, `src` and `libtexpdf-src` attributes that are given by the
# `flake.nix`. In Nixpkgs, we don't need `libtexpdf-src` because we use
# `fetchFromGitHub` with fetchSubmodules = true;`.
{
  lib,
  stdenv,
  autoreconfHook,
  gitMinimal,
  src,
  version,

  # nativeBuildInputs
  pkg-config,
  jq,
  cargo,
  rustc,
  rustPlatform,
  luarocks,

  # buildInputs
  cargo-edit,
  lua,
  harfbuzz,
  icu,
  fontconfig,
  libiconv,
  libxslt,
  stylua,
  taplo,
  typos,
  # FONTCONFIG_FILE
  makeFontsConf,
  gentium,

  # passthru.tests
  runCommand,
  poppler_utils,

  # This package
  libtexpdf-src,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sile";
  inherit version src;

  # In Nixpkgs, we don't copy the Cargo.lock file from the repo to Nixpkgs'
  # repo, but we inherit src, and specify a hash (it is a fixed output
  # derivation). `nix-update` and `nixpkgs-update` should be able to catch that
  # hash and update it as well when performing updates.
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ../Cargo.lock;
  };

  nativeBuildInputs = [
    autoreconfHook
    gitMinimal
    pkg-config
    jq
    cargo
    rustc
    rustPlatform.cargoSetupHook
    luarocks
  ];
  # luarocks propagates cmake, but it shouldn't be used as a build system.
  dontUseCmakeConfigure = true;

  preAutoreconf = ''
    # Add the libtexpdf src instead of the git submodule. (From some reason
    # without --no-preserve=mode flag, libtexpdf/ is unwriteable). As explained
    # before, in Nixpkgs, we won't need to run these commands.
    rm -rf ./libtexpdf
    cp --no-preserve=mode -r ${libtexpdf-src} ./libtexpdf/
    # pretend to be a tarball release so sile --version will not say `vUNKNOWN`,
    # but don't pretend so hard we make the build system treat us like the tarball.
    echo ${finalAttrs.version} > .flake-version
    sed -i -e 's/tarball-version/flake-version/' configure.ac
  '';

  buildInputs =
    [
      finalAttrs.finalPackage.passthru.luaEnv
      cargo-edit
      harfbuzz
      icu
      fontconfig
      libiconv
      libxslt
      stylua
      taplo
      typos
    ];

  configureFlags =
    [
      # Nix will supply all the Lua dependencies, so stop the build system from
      # bundling vendored copies of them.
      "--with-system-lua-sources"
      "--with-system-luarocks"
      # The automake check target uses pdfinfo to confirm the output of a test
      # run, and uses autotools to discover it. Nix builds have to that test
      # because it is run from the source directory with a binary already built
      # with system paths, so it can't be checked under Nix until after install.
      # After install the Makefile isn't available of course, so we have our own
      # copy of it with a hard coded path to `pdfinfo`. By specifying some binary
      # here we skip the configure time test for `pdfinfo`, by using `false` we
      # make sure that if it is expected during build time we would fail to build
      # since we only provide it at test time.
      "PDFINFO=false"
    ]
    ++ lib.optionals (!lua.pkgs.isLuaJIT) [
      "--without-luajit"
    ];

  postPatch = ''
    patchShebangs build-aux/*.sh build-aux/git-version-gen
  '';

  FONTCONFIG_FILE = makeFontsConf {
    fontDirectories = [
      gentium
    ];
  };

  enableParallelBuilding = true;

  # See commentary in bootstrap.sh; we're getting AMINCCLUDE stuff inlined
  # instead of included but need to avoid a file not found error on first run.
  postUnpack = ''
    touch source/aminclude.am
  '';

  passthru = {

    luaPackages =
      [
        # modules used at runtime
        "cassowary"
        "cldr"
        "fluent"
        "linenoise"
        "loadkit"
        "lpeg"
        "lua-zlib"
        "lua_cliargs"
        "luaepnf"
        "luaexpat"
        "luafilesystem"
        "luarepl"
        "luasec"
        "luasocket"
        "luautf8"
        "penlight"
        "vstruct"
        # lua packages needed for testing
        "busted"
        "luacheck"
        # packages needed for building api docs
        "ldoc"
      ]
      ++ lib.optionals (lib.versionOlder lua.luaversion "5.2") [
        "bit32"
      ]
      ++ lib.optionals (lib.versionOlder lua.luaversion "5.3") [
        "compat53"
      ];
    luaEnv = lua.withPackages (ps: lib.attrVals finalAttrs.finalPackage.passthru.luaPackages ps);

    # Copied from Makefile.am
    tests.test = lib.optionalAttrs (!(stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64)) (
      runCommand "${finalAttrs.pname}-test"
        {
          nativeBuildInputs = [
            poppler_utils
            finalAttrs.finalPackage
          ];
          inherit (finalAttrs) FONTCONFIG_FILE;
        }
        ''
          output=$(mktemp -t selfcheck-XXXXXX.pdf)
          echo "<sile>foo</sile>" | sile -o $output -
          pdfinfo $output | grep "SILE v${finalAttrs.version}" > $out
        ''
    );
  };

  outputs = [
    "out"
    "doc"
    "man"
    "dev"
  ];

  meta = {
    description = "Typesetting system";
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
    changelog = "https://github.com/sile-typesetter/sile/raw/master/CHANGELOG.md";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [
      doronbehar
      alerque
    ];
    license = lib.licenses.mit;
  };
})
