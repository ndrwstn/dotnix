# systems/nixos/hyprland.nix
# Hyprland configuration for NixOS systems
{ pkgs, inputs, ... }:

{
  # Hyprland and Wayland support
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # Use GDM as the display manager (already enabled in systems/nixos/default.nix)
  # GDM will automatically detect and show Hyprland as a session option

  # Polkit authentication agent will be handled in user config
  security.polkit.enable = true;

  # XDG portals for file pickers, screenshots, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Environment variables for Wayland
  environment.variables = {
    # Force GTK to use Wayland backend
    GDK_BACKEND = "wayland";

    # Qt Wayland backend
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # XDG session type
    XDG_SESSION_TYPE = "wayland";

    # Cursor theme for Wayland
    XCURSOR_THEME = "breeze_cursors";
    XCURSOR_SIZE = "24";
  };

  # Required for some Wayland applications
  hardware.graphics.enable = true;

  # Allow swaylock to unlock the screen
  security.pam.services.swaylock = { };
}
