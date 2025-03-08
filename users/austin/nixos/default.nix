# users/austin/nixos/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    # nixos settings that don't deserve separate flake
  }

  # nixos flakes
  (import ./packages.nix {inherit config pkgs;})
]
