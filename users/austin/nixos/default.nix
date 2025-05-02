# users/austin/nixos/default.nix
{
  config,
  pkgs,
  # unstable,
  lib,
  ...
}:
lib.mkMerge [
  {
    # nixos settings that don't deserve separate flake
    services.dbus.enable = true;
  }

  # nixos flakes
  (import ./packages.nix {inherit config pkgs;})
]
