{ pkgs ? import ./nixpkgs { }
, stdenvNoCC ? pkgs.stdenvNoCC
, nix ? pkgs.nix
, racket ? pkgs.callPackage ./racket-minimal.nix {}
, racket-catalog ? ./catalog.rktd
}:

let
  stage0-nix = stdenvNoCC.mkDerivation {
    name = "racket2nix-stage0.nix";
    src = ./nix;
    buildInputs = [ nix racket ];
    phases = "unpackPhase installPhase";
    installPhase = ''
      racket -N racket2nix ./racket2nix.rkt --catalog ${racket-catalog} $src > $out
    '';
  };
  stage0 = pkgs.callPackage stage0-nix { inherit racket; };
in
stage0 // { nix = stage0-nix; }
