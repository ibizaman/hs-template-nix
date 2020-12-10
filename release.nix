{ compiler ? "ghc865"
, pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/20.09.tar.gz") {}
}:

let
  inherit (pkgs.haskell.lib) dontCheck;

  haskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = self: super: rec {
      hs-template-nix = self.callCabal2nix "hs-template-nix" ./. { };

      hspec = self.callHackage "hspec" "2.7.1" {};
      hspec-core = self.callHackage "hspec-core" "2.7.1" {};
      hspec-discover = self.callHackage "hspec-discover" "2.7.1" {};

      hpack = dontCheck (self.callHackage "hpack" "0.34.1" {});
      Cabal = dontCheck (self.callHackage "Cabal" "3.0.2.0" {});

      hoogle = dontCheck (self.callHackage "hoogle" "5.0.18" {});
    };
  };

  shellHaskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = self: super: rec {
      hpack = dontCheck (self.callHackage "hpack" "0.34.1" {});
      Cabal = dontCheck (self.callHackage "Cabal" "3.0.2.0" {});

      stack = dontCheck (self.callHackage "stack" "2.3.1" {});
      hackage-security = dontCheck (self.callHackage "hackage-security" "0.6.0.0" {});
      pantry = dontCheck (self.callHackage "pantry" "0.4.0.1" {});

      hoogle = dontCheck (self.callHackage "hoogle" "5.0.18" {});
    };
  };

  project = haskellPackages.hs-template-nix;
in
{
  inherit project;

  shell = haskellPackages.shellFor {
    packages = p: with p; [
      project
    ];
    buildInputs = with shellHaskellPackages; [
      stack
      ghcide
      brittany
      hlint
    ];
    withHoogle = true;
  };
}
