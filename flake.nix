{
  description = "Simon’s Improved Layout Engine";

  # To make user overrides of the nixpkgs flake not take effect
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # TODO: Should this be replaced with libtexpdf package from nixpkgs? or
  # should we keep it that way, so that it'd be easy to test new versions
  # of libtexpdf when developing?
  inputs.libtexpdf-src = {
    url = "github:sile-typesetter/libtexpdf";
    flake = false;
  };

  # https://nixos.wiki/wiki/Flakes#Using_flakes_project_from_a_legacy_Nix
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self
    , nixpkgs
    , flake-utils
    , flake-compat
    , gitignore
    , libtexpdf-src
  }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      inherit (gitignore.lib) gitignoreSource;
      # https://discourse.nixos.org/t/passing-git-commit-hash-and-tag-to-build-with-flakes/11355/2
      version_rev = if (self ? rev) then (builtins.substring 0 7 self.rev) else "dirty";
      # Prepare a different luaEnv to be used in the overridden expression,
      # this is also the place to choose a different lua interpreter, such as
      # lua5_4 or luajit
      luaEnv = pkgs.lua5_3.withPackages(ps: with ps; [
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
        semver
        vstruct
        # lua packages needed for testing
        busted
        luacheck
        # If we want to test things with lua5.2 or an even older lua, we uncomment these
        #bit32
        #compat53
      ]);
      # Use the expression from Nixpkgs instead of rewriting it here.
      sile = pkgs.sile.overrideAttrs(oldAttr: rec {
        version = "${(pkgs.lib.importJSON ./package.json).version}-${version_rev}-flake";
        src = pkgs.lib.cleanSourceWith {
          # Ignore many files that gitignoreSource doesn't ignore, see:
          # https://github.com/hercules-ci/gitignore.nix/issues/9#issuecomment-635458762
          filter = path: type:
          ! (builtins.any (r: (builtins.match r (builtins.baseNameOf path)) != null) [
            # Nix files
            "flake.nix"
            "flake.lock"
            "default.nix"
            "shell.nix"
            # git commit and editing format files
            ".commitlintrc.yml"
            "package.json"
            ".husky"
            ".editorconfig"
            # CI files
            ".cirrus.yml"
            ".github"
            "action.yml"
            "azure-pipelines.yml"
            "Dockerfile"
            # Git files
            ".gitattributes"
            ".git"
          ]);
          src = gitignoreSource ./.;
        };
        # Add the libtexpdf src instead of the git submodule.
        # Also pretend to be a tarball release so sile --version will not say `vUNKNOWN`.
        preAutoreconf = ''
          rm -rf ./libtexpdf
          # From some reason without this flag, libtexpdf/ is unwriteable
          cp --no-preserve=mode -r ${libtexpdf-src} ./libtexpdf/
          echo ${version} > .tarball-version
        '';
        # Don't build the manual as it's time consuming, and it requires fonts
        # that are not available in the sandbox due to internet connection
        # missing.
        configureFlags = pkgs.lib.lists.remove "--with-manual" oldAttr.configureFlags;
        nativeBuildInputs = oldAttr.nativeBuildInputs ++ [
          pkgs.autoreconfHook
        ];
        buildInputs = [
          # Add here inputs needed for development, and not for Nixpkgs' build.
          pkgs.libarchive
          pkgs.perl
          # This line, along with the `pkgs.list.drop 1` line afterwards,
          # replaces the luaEnv originated in `oldAttr.buildInputs`.
          luaEnv
        ] ++ (
          # Add all buildInputs from Nixpkgs' derivation, besides the 1st
          # one, which is Nixpkgs' luaEnv. NOTE it's not mandatory to `drop`
          # the first buildInput of `oldAttr` as so, because the first `lua`
          # interpreter that would have been found otherwise would have been
          # the one belonging to the first `luaEnv` of the final
          # `buildInputs`. However, we'd like to keep the `buildInputs` clean
          # never the less.
          pkgs.lib.lists.drop 1 oldAttr.buildInputs
        );
        meta = oldAttr.meta // {
          changelog = "https://github.com/sile-typesetter/sile/raw/master/CHANGELOG.md";
        };
      });
    in rec {
      devShells = {
        default = pkgs.mkShell {
          inherit (sile) checkInputs buildInputs FONTCONFIG_FILE;
          configureFlags =  sile.configureFlags ++ [ "--enable-developer" ];
          nativeBuildInputs = sile.nativeBuildInputs ++ [ pkgs.luarocks-nix ];
          # This is written in Nixpkgs' expression as well, but we need to write
          # this here so that the overridden luaEnv will be used instead.
          passthru = {
            inherit luaEnv;
          };
        };
      };
      packages.sile = sile;
      defaultPackage = sile;
      apps = rec {
        default = sile;
        sile = {
          type = "app";
          program = "${self.defaultPackage.${system}}/bin/sile";
        };
      };
      defaultApp = apps.sile;
    }
  );
}
