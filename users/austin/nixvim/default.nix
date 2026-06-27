# users/austin/nixvim/default.nix
{ config
, pkgs
, lib
, texlivePackage
, unstable
, ...
}:
lib.mkMerge [
  {
    enable = true;
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };
    # Use host system's nixpkgs (nixpkgs-darwin on macOS, nixpkgs on NixOS)
    # instead of nixvim's own pinned nixpkgs. This avoids cross-nixpkgs
    # conflicts (e.g., two different luajit builds in the same buildEnv).
    # allowUnfree is set at the system level, so it doesn't need to be here.
    nixpkgs.useGlobalPackages = true;
    extraPackages = [
      texlivePackage
      pkgs.texlab
      # provide correct viewer depending on environment
      (if pkgs.stdenv.isDarwin then pkgs.skim else pkgs.zathura)
      # Add build tools for compilation (fixes gcc errors)
      pkgs.stdenv.cc # Complete C/C++ toolchain with headers
      pkgs.pkg-config # Library discovery tool often needed by build systems
      pkgs.gnumake # Make build tool (commonly required)
    ];
  }
  (import ./keymaps.nix)
  (import ./plugins.nix { inherit pkgs texlivePackage lib; })
  (import ./options.nix)
  (import ./extra.nix { inherit pkgs unstable config; })
]
