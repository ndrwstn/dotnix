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
      # 1Password CLI integration
      OP_PLUGIN_ALIASES_SOURCED = "1";
      # Prevent GNOME keyring conflicts with 1Password SSH agent
      GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
    };
  }

  # nixos flakes
  (import ./packages.nix { inherit config pkgs; })
]
