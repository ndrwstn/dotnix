# users/austin/nixos/default.nix
{ config
, pkgs
, # unstable,
  lib
, ...
}:
lib.mkMerge [
  {
    # nixos settings that don't deserve separate flake
    # Environmental Variables
    home.sessionVariables = {
      # Set default editor to nvim
      EDITOR = "nvim";
    };
  }

  # nixos flakes
  (import ./packages.nix { inherit config pkgs; })
]
