{ hackFixes, includeSolaar ? true }:

[
  (import ./1password-cli.nix)
  (import ./ghostty.nix)
  (import ./vim-plugins.nix)
]
++ (if includeSolaar
then hackFixes.nixos.overlays
else hackFixes.nixos.overlaysWithoutSolaar)
