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
      # language servers
      pkgs.lua-language-server
      pkgs.marksman
      pkgs.nil
      pkgs.pyright
      pkgs.sqls
      # formatters
      pkgs.black
      pkgs.isort
      pkgs.nixpkgs-fmt
      pkgs.nodePackages.prettier
      pkgs.shfmt
      pkgs.sqlfluff
      pkgs.stylua
      pkgs.taplo
    ];
	}
  (import ./keymaps.nix)
  (import ./plugins.nix {inherit pkgs;})
  (import ./options.nix)
  (import ./extra.nix {inherit pkgs;})
]

