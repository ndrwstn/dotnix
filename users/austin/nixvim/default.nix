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
    # allow unfree - needed for copilot-language-server
    nixpkgs.config.allowUnfree = true;
    extraPackages = [
      texlivePackage
      pkgs.texlab
      # provide correct viewer depending on environment
      (if pkgs.stdenv.isDarwin then pkgs.skim else pkgs.zathura)
      # Add build tools for compilation (fixes gcc errors)
      pkgs.stdenv.cc # Complete C/C++ toolchain with headers
      pkgs.pkg-config # Library discovery tool often needed by build systems
      pkgs.gnumake # Make build tool (commonly required)
      # Prose/writing toolchain:
      pkgs.vale # style linter (proselint-port + LegalRules via ~/.config/vale)
      pkgs.ltex-ls-plus # LSP server; remote LanguageTool for grammar
      pkgs.markdownlint-cli # markdown structural linter
      pkgs.codespell # typo catcher for code + prose
    ];

    # Enable native spellcheck only on prose filetypes so code buffers
    # stay clean. spelllang defaults come from options.nix (en_us).
    autoCmd = [
      {
        event = "FileType";
        pattern = [ "markdown" "text" "tex" "gitcommit" ];
        command = "setlocal spell";
      }
    ];
  }
  (import ./keymaps.nix)
  (import ./plugins.nix { inherit pkgs texlivePackage lib; })
  (import ./options.nix)
  (import ./extra.nix { inherit pkgs unstable config; })
]
