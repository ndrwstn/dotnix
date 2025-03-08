# users/austin/darwin/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    # darwin settings that don't deserve separate flake
  }

  # darwin flakes
  (import ./system.nix {inherit config pkgs;})
]
