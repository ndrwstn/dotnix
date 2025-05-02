# users/austin/nixvim/default.nix
{
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
			pkgs.nil
			pkgs.pyright
			pkgs.lua-language-server
			pkgs.marksman
			pkgs.sqls
		];
	}
  (import ./keymaps.nix)
  (import ./plugins.nix {inherit pkgs;})
  (import ./options.nix)
  (import ./extra.nix {inherit pkgs;})
]

