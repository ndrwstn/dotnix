# users/austin/nixos/default.nix
{ config
, pkgs
, unstable
, lib
, osConfig ? { }
, ...
}:
let
  windowManagers = osConfig._astn.machine.windowManagers or [
    "gnome"
    "hyprland"
  ];
  hasWindowManager = name: builtins.elem name windowManagers;
in
lib.mkMerge [
  {
    # nixos settings that don't deserve separate flake
    # Environmental Variables
    home.sessionVariables = {
      # Set default editor to nvim
      EDITOR = "nvim";
      # 1Password CLI integration
      OP_PLUGIN_ALIASES_SOURCED = "1";
      # Force SSH to use 1Password agent socket
      SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
    };

    # Cursor theme configuration (unified across Wayland/X11/GTK)
    home.pointerCursor = {
      name = "breeze_cursors";
      size = 24;
      package = pkgs.kdePackages.breeze;
      gtk.enable = true;
    };
  }

  # nixos packages
  (import ./packages.nix { inherit config pkgs unstable; })

  # NixOS-only shell theming
  (import ./ohmyposh.nix { inherit config; })

  # Hyprland configuration
  (lib.mkIf (hasWindowManager "hyprland")
    (import ./hyprland { inherit config pkgs unstable lib; }))

  # i3 configuration
  (lib.mkIf (hasWindowManager "i3")
    (import ./i3 { inherit config pkgs unstable lib; }))

  # Vicinae launcher configuration
  (import ./vicinae.nix { inherit config pkgs lib; })
]
