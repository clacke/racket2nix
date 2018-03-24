{ pkgs ? import <nixpkgs> { }
, stdenvNoCC ? pkgs.stdenvNoCC
, racket ? pkgs.callPackage ./racket-minimal.nix {}
, cacert ? pkgs.cacert
, racket-catalog ? pkgs.callPackage ./catalog.nix { inherit racket; }
, racket2nix-stage0 ? pkgs.callPackage ./stage0.nix { inherit racket; }
, racket2nix-stage0-nix ? racket2nix-stage0.racket2nix-stage0-nix
}:

let attrs = rec {
  racket2nix-nix = stdenvNoCC.mkDerivation {
    name = "racket2nix.nix";
    src = ./nix;
    buildInputs = [ racket2nix-stage0 ];
    phases = "unpackPhase installPhase";
    installPhase = ''
      racket2nix --catalog ${racket-catalog} ../nix > $out
      diff ${racket2nix-stage0-nix} $out
    '';
  };
  racket2nix = (pkgs.callPackage racket2nix-nix { inherit racket; }).overrideDerivation (drv: rec {
    src = ./nix;
    srcs = [ src ];
    postInstall = ''
      $out/bin/racket2nix --test
    '';
  });
};
in
attrs.racket2nix // attrs
