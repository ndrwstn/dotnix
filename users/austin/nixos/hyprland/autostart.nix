# users/austin/nixos/hyprland/autostart.nix
# Autostart applications for Hyprland
{ pkgs, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      background-color = "#2E3440";
      text-color = "#D8DEE9";
      border-color = "#5E81AC";
      border-size = 2;
      border-radius = 8;
      default-timeout = 5000;
      font = "Sans 10";
    };
  };

  # Hyprlock - screen locker for Hyprland
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [{
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      }];

      input-field = [{
        size = "200, 50";
        outline_thickness = 3;
        dots_size = 0.33;
        dots_spacing = 0.15;
        dots_center = true;
        outer_color = "rgb(94, 129, 172)";
        inner_color = "rgb(46, 52, 64)";
        font_color = "rgb(216, 222, 233)";
        fade_on_empty = true;
        placeholder_text = "<i>Password...</i>";
        hide_input = false;
        position = "0, -20";
        halign = "center";
        valign = "center";
      }];
    };
  };

  # Hypridle - idle daemon for Hyprland
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300; # 5 minutes
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330; # 5.5 minutes
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800; # 30 minutes
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  wayland.windowManager.hyprland.settings.exec-once = [
    # Start Waybar
    "${pkgs.waybar}/bin/waybar"

    # Polkit authentication agent
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

    # Note: 1Password starts via systemd user service (WantedBy=graphical-session.target)
    # No manual start needed - systemd.enable = true in default.nix handles session target

    # Set background wallpaper using swww
    "${pkgs.swww}/bin/swww init"
    "${pkgs.swww}/bin/swww img ~/.wallpaper.jpg"
  ];
}
