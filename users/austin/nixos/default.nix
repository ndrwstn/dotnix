# users/austin/nixos/default.nix
{ config
, pkgs
, unstable
, lib
, osConfig ? { }
, ...
}:
let
  onePasswordSshAuthSock = "${config.home.homeDirectory}/.1password/agent.sock";
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
    };

    # Keep graphical user services pointed at the local 1Password agent.
    # Interactive shells set SSH_AUTH_SOCK conditionally below so remote SSH
    # logins preserve sshd's forwarded /tmp/ssh-*/agent.* socket.
    systemd.user.sessionVariables = {
      SSH_AUTH_SOCK = onePasswordSshAuthSock;
    };

    programs.zsh.initContent = lib.mkAfter ''
      # Use the local 1Password SSH agent in local shells, but do not override
      # sshd's forwarded SSH_AUTH_SOCK when this shell is running over SSH.
      if [ -z "$SSH_CONNECTION" ]; then
        export SSH_AUTH_SOCK="${onePasswordSshAuthSock}"
      fi
    '';

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

  # Optional application presets
  (import ./presets { inherit config pkgs unstable lib osConfig; })

  # NixOS-only shell theming
  (import ./ohmyposh.nix { inherit config; })

  # 1Password GUI/agent autostart for Austin's graphical sessions
  (import ./1password.nix { inherit pkgs lib; })

  # Hyprland configuration
  (lib.mkIf (hasWindowManager "hyprland")
    (import ./hyprland { inherit config pkgs unstable lib; }))

  # i3 configuration
  (lib.mkIf (hasWindowManager "i3")
    (import ./i3 { inherit config pkgs unstable lib; }))

  # Vicinae launcher configuration
  (import ./vicinae.nix { inherit config pkgs lib osConfig; })

  # AirPlay receiver configuration for Siberia
  (import ./shairport-sync.nix { inherit config pkgs unstable lib osConfig; })
]
