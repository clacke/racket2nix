{ isTravis ? false
, pkgs ? import ./pkgs
, cacert ? (pkgs {}).cacert
}:

let
  inherit (pkgs {}) lib buildRacketPackage;

  genJobs = pkgs: rec {
    api = {
      # buildRacket is tested by ./integration-tests
      # buildRacketCatalog is tested by ./integration-tests
      # buildRacketPackage is tested by ./test.nix
      override-racket-derivation = (buildRacketPackage ./nix).overrideRacketDerivation (oldAttrs: {});
      one-liner = {
        string = pkgs.callPackage ./. { package = "gui-lib"; };
        path = pkgs.callPackage ./. { package = ./nix; };
      };
    };
    pkgs-all = pkgs.callPackage <racket2nix/catalog.nix> {};
    racket2nix = pkgs.callPackage <racket2nix> {};
    tests = {
      inherit (pkgs.callPackage <racket2nix/test.nix> {}) light-tests;
    } // lib.optionalAttrs ((builtins.match ".*racket-minimal.*" pkgs.racket.name) != null) {
      inherit (pkgs.callPackage <racket2nix/test.nix> {}) all-checked-packages heavy-tests;
    };
  };
in
  (genJobs (pkgs {})) //
  {
    racket-packages-updated = (pkgs {}).runCommand "racket-packages-updated" rec {
      src = <racket2nix>;
      inherit (pkgs {}) racket2nix;
      buildInputs = [ cacert racket2nix ];
    } ''
      set -e; set -u
      racket2nix --catalog $src/catalog.rktd > racket-packages.nix
      if ! diff -u $src/racket-packages.nix racket-packages.nix > $out; then
        echo racket-packages.nix has not been kept up-to-date, please regenerate and commit.
        echo missing changes:
        diff -u racket-packages.nix $src/racket-packages.nix
      fi
    '';
    latest-nixpkgs = genJobs (pkgs { pkgs = import <nixpkgs>; });
    x86_64-darwin = genJobs (pkgs { system = "x86_64-darwin"; }) // {
      latest-nixpkgs = genJobs (pkgs { pkgs = import <nixpkgs>; system = "x86_64-darwin"; });
    };
  } // lib.optionalAttrs (pkgs {}).racket-full.meta.available {
    racket-full = genJobs (pkgs { overlays = [ (self: super: { racket = self.racket-full; }) ]; });
  } // lib.optionalAttrs isTravis {
    stage0-nix-prerequisites = (pkgs {}).racket2nix-stage0.buildInputs;
    travisOrder = [ "pkgs-all" "stage0-nix-prerequisites" "racket2nix" "tests.light-tests"
                    "racket-packages-updated"
                    "racket-full.racket2nix" "api.override-racket-derivation" ];
  }
