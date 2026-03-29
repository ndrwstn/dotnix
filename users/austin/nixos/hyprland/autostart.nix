# users/austin/nixos/hyprland/autostart.nix
# Autostart applications for Hyprland
{ pkgs, lib, config, ... }:

{
  # mako notification daemon - colors are managed by matugen
  services.mako = {
    enable = true;
    # No settings here - matugen generates ~/.config/mako/config with dynamic colors
    # Settings for border-radius, timeout, font will come from the template
  };

  # Create wallpaper directories on activation
  home.activation.createWallpaperDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Pictures/Wallpapers/Favorites"
    mkdir -p "${config.home.homeDirectory}/Pictures/Wallpapers/Staging"
  '';

  wayland.windowManager.hyprland.settings.exec-once = [
    # Polkit authentication agent
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

    # Clipboard history watchers
    "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
    "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"

    # Note: 1Password starts via systemd user service (WantedBy=graphical-session.target)
    # No manual start needed - systemd.enable = true in default.nix handles session target

  ];
}
