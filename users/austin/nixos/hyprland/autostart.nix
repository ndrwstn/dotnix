# users/austin/nixos/hyprland/autostart.nix
# Autostart applications for Hyprland
{ pkgs, lib, config, ... }:

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

  # Create wallpaper directories on activation
  home.activation.createWallpaperDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Pictures/Wallpapers/favorites"
    mkdir -p "${config.home.homeDirectory}/Pictures/Wallpapers/staging"
  '';

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

    # Initialize swww wallpaper daemon
    "${pkgs.swww}/bin/swww init"

    # Note: First wallpaper is set by the wallpaper-rotate service after boot
    # To set manually: swww img ~/Pictures/Wallpapers/favorites/your-image.jpg
  ];
}
