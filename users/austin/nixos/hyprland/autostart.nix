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

  wayland.windowManager.hyprland.settings.exec-once = [
    # Start Waybar
    "${pkgs.waybar}/bin/waybar"

    # Polkit authentication agent
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

    # Clipboard history watchers
    "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
    "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"

    # Note: 1Password starts via systemd user service (WantedBy=graphical-session.target)
    # No manual start needed - systemd.enable = true in default.nix handles session target

    # Set background wallpaper using swww
    "${pkgs.swww}/bin/swww init"
    "${pkgs.swww}/bin/swww img ~/.wallpaper.jpg"
  ];
}
