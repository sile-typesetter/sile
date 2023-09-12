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
      sile = pkgs.callPackage ./pkg.nix {
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
        inherit libtexpdf-src;
      };
      inherit (sile.passthru) luaEnv;
    in rec {
      devShells = {
        default = pkgs.mkShell {
          inherit (sile)
            buildInputs
            nativeCheckInputs
            FONTCONFIG_FILE
          ;
          configureFlags =  sile.configureFlags ++ [ "--enable-developer" ];
          nativeBuildInputs = sile.nativeBuildInputs ++ [
            pkgs.luarocks
            # For commitlint git hook
            pkgs.yarn
          ];
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
