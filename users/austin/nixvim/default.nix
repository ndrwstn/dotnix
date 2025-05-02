# users/austin/nixvim/default.nix
{
  pkgs,
  lib,
  texlivePackage,
  ...
}:
lib.mkMerge [
  (import ./keymaps.nix)
  (import ./plugins.nix {inherit pkgs;})
  (import ./options.nix)
  (import ./lsp.nix)
  (import ./languages.nix)
  (import ./extra.nix {inherit pkgs;})
  {extraPackages = [texlivePackage];}
]
