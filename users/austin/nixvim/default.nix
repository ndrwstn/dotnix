# users/austin/nixvim/default.nix
{ config
, pkgs
, lib
, texlivePackage
, ...
}:
lib.mkMerge [
  {
    enable = true;
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };
    extraPackages = [
      texlivePackage
      # provide correct viewer depending on environment
      (if pkgs.stdenv.isDarwin then pkgs.skim else pkgs.zathura)
      # Add build tools for compilation (fixes gcc errors)
      pkgs.stdenv.cc # Complete C/C++ toolchain with headers
      pkgs.pkg-config # Library discovery tool often needed by build systems
      pkgs.gnumake # Make build tool (commonly required)
    ];
  }
  (import ./keymaps.nix)
  (import ./plugins.nix { inherit pkgs texlivePackage; })
  (import ./options.nix)
  (import ./extra.nix { inherit pkgs; })
]

