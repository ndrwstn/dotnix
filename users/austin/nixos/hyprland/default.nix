# users/austin/nixos/hyprland/default.nix
# Main Hyprland configuration
{ pkgs, unstable, lib, config, ... }:

lib.mkMerge [
  (import ./autostart.nix { inherit pkgs unstable lib config; })
  (import ./gestures.nix { inherit pkgs unstable lib config; })
  (import ./keymaps.nix { inherit pkgs unstable lib config; })
  (import ./waybar.nix { inherit pkgs unstable lib config; })
  {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null; # Use system-installed Hyprland to avoid conflicts
      portalPackage = null; # Use system-installed portal to avoid conflicts
      systemd.enable = true; # Enable systemd integration for proper graphical-session.target activation
      systemd.variables = [ "--all" ]; # Export all env vars to systemd user session

      settings = {
        # Monitor configuration
        monitor = [
          ",preferred,auto,1"
        ];

        # Input configuration
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";

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
          "col.active_border" = "rgba(94,129,172,1)";
          "col.inactive_border" = "rgba(46,52,64,1)";
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
            color = "rgba(0,0,0,0.3)";
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

        # Window rules
        windowrulev2 = [
          "float,class:^(pavucontrol)$"
          "float,class:^(blueman-manager)$"
          "float,class:^(nm-connection-editor)$"
          "float,class:^(gnome-disks)$"
          "float,class:^(gparted)$"
        ];

        # Workspace configuration
        workspace = [
          "1,monitor:HDMI-A-1,default"
          "2,monitor:HDMI-A-1,default"
          "3,monitor:HDMI-A-1,default"
          "4,monitor:HDMI-A-1,default"
          "5,monitor:HDMI-A-1,default"
        ];
      };
    };

  }
]
