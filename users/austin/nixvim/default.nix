# users/austin/nixvim/default.nix
{
  config,
  pkgs,
  lib,
  texlivePackage,
  ...
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
    ];
  }
  (import ./keymaps.nix)
  (import ./plugins.nix { inherit pkgs texlivePackage; })
  (import ./options.nix)
  (import ./extra.nix { inherit pkgs; })
]

