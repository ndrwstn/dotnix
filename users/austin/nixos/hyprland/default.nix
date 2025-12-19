# users/austin/nixos/hyprland/default.nix
# Main Hyprland configuration
{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;

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
        accel_profile = "flat";

        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
        };
      };

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        col.active_border = "rgba(94,129,172,1)";
        col.inactive_border = "rgba(46,52,64,1)";
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
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        col.shadow = "rgba(0,0,0,0.3)";
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
      windowrule = [
        "float,^(pavucontrol)$"
        "float,^(blueman-manager)$"
        "float,^(nm-connection-editor)$"
        "float,^(gnome-disks)$"
        "float,^(gparted)$"
      ];

      # Workspace configuration
      workspace = [
        "1,monitor:HDMI-A-1,default"
        "2,monitor:HDMI-A-1,default"
        "3,monitor:HDMI-A-1,default"
        "4,monitor:HDMI-A-1,default"
        "5,monitor:HDMI-A-1,default"
      ];

      # Autostart applications
      exec-once = [
        "waybar"
        "mako"
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
        "systemctl --user start 1password"
      ];
    };
  };
}
