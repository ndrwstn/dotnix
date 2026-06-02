# users/austin/nixos/hyprland/default.nix
# Main Hyprland configuration
{ pkgs, unstable, lib, config, ... }:

let
  terminalPackage = unstable.ghostty;
  terminalCommand = "${terminalPackage}/bin/ghostty --working-directory=\"$HOME\"";
  browserPackage = unstable.librewolf;
  browserCommand = lib.getExe browserPackage;
  passwordManagerPackage = pkgs._1password-gui;
  passwordManagerCommand = lib.getExe passwordManagerPackage;
  fileManagerPackage = pkgs.pcmanfm;
  fileManagerCommand = lib.getExe fileManagerPackage;
  networkEditorPackage = pkgs.networkmanagerapplet;
  networkEditorCommand = "${networkEditorPackage}/bin/nm-connection-editor";
  audioControlPackage = pkgs.pavucontrol;
  audioControlCommand = "${audioControlPackage}/bin/pavucontrol";
in

lib.mkMerge [
  (import ./autostart.nix { inherit pkgs unstable lib config; })
  (import ./gestures.nix { inherit pkgs unstable lib config; })
  (import ./keymaps.nix {
    inherit pkgs terminalCommand browserCommand passwordManagerCommand
      fileManagerCommand networkEditorCommand audioControlCommand;
  })
  (import ./waybar.nix { inherit pkgs unstable lib config; })
  (import ./wlogout.nix { inherit pkgs unstable lib config; })
  (import ./awww.nix { inherit pkgs unstable lib config; })
  (import ./matugen.nix { inherit pkgs unstable lib config; })
  (import ./windows.nix { inherit pkgs unstable lib config; })
  {
    home.packages = with pkgs; [
      terminalPackage
      browserPackage
      passwordManagerPackage
      fileManagerPackage
      brightnessctl
      cliphist
      grim
      mako
      matugen
      networkEditorPackage
      audioControlPackage
      polkit_gnome
      slurp
      awww
      waybar
      wl-clipboard
      wlogout
      wofi
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = null; # Use system-installed Hyprland to avoid conflicts
      configType = "hyprlang"; # Use hyprlang format (default changed to lua in 26.05)
      portalPackage = null; # Use system-installed portal to avoid conflicts
      systemd.enable = true; # Enable systemd integration for proper graphical-session.target activation
      # Keep graphical-session.target aware of the compositor environment without
      # importing SSH_AUTH_SOCK from GDM/GCR over the 1Password agent socket.
      systemd.variables = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "HYPRLAND_INSTANCE_SIGNATURE"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_TYPE"
        "XDG_SESSION_DESKTOP"
        "DESKTOP_SESSION"
        "PATH"
        "XDG_DATA_DIRS"
        "XDG_CONFIG_DIRS"
        "XCURSOR_PATH"
        "MOZ_ENABLE_WAYLAND"
      ];

      settings = {
        # Monitor configuration
        monitor = [
          "eDP-1,preferred,auto,1.25"
          ",preferred,auto,1"
        ];

        # Input configuration
        input = {
          kb_layout = "us";

          follow_mouse = 1;
          sensitivity = 0;
          accel_profile = "adaptive"; # GNOME-style speed-dependent acceleration

          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            clickfinger_behavior = true; # Enable finger-count-based clicking
            tap-to-click = true; # Tap to click (1-tap=left, 2-tap=right, 3-tap=middle)
            drag_lock = true; # Can lift finger briefly during drag without dropping
          };
        };

        # General settings
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          resize_on_border = true;
        };

        # Decoration settings
        decoration = {
          rounding = 8;
          blur = {
            enabled = true;
            size = 3;
            passes = 2;
          };

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
          };
        };

        # Animation settings
        animations = {
          enabled = true;
          animation = [
            "windows,1,3,default"
            "border,1,10,default"
            "fade,1,10,default"
            "workspaces,1,5,default"
          ];
        };

        # Window rules (hyprland 0.55+ inline syntax)
        windowrule = [
          "match:class ^(pavucontrol)$, float on"
          "match:class ^(blueman-manager)$, float on"
          "match:class ^(nm-connection-editor)$, float on"
          "match:class ^(gnome-disks)$, float on"
          "match:class ^(gparted)$, float on"

          # OpenCode - ignore app-requested maximize and float project picker
          "match:class ^\\.OpenCode-unwrapped$, suppress_event maximize"
          "match:title ^(Open project)$, float on, size 90% 90%, center on"

          # GCS - GURPS Character Sheet (XWayland/GLFW application)
          "match:class ^(GCS)$, tile on"
          "match:class ^(GCS)$, no_max_size on"
        ];

        # Workspace configuration
        workspace = [
          "1,persistent:true"
          "10,persistent:true"
        ];
      };

      extraConfig = ''
        # Color management: disable on Intel Haswell GPU (avoids FP16 rendering issues)
        # Note: cm_enabled only works at startup, not runtime
        render:use_fp16 = 0
        render:cm_enabled = false

        # Source matugen-generated colors
        source = ${config.xdg.cacheHome}/matugen/hyprland-colors.conf
      '';
    };

  }
]
