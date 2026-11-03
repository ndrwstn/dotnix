{ hackFixes }:

[
  (import ./1password-cli.nix)
  (import ./ghostty.nix)
  (import ./vim-plugins.nix)
]
++ hackFixes.nixos.overlays
