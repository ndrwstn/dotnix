# systems/nixos/hyprland.nix
# Hyprland configuration for NixOS systems
{ pkgs, ... }:

{
  # Hyprland and Wayland support - module handles package and portal automatically
  programs.hyprland.enable = true;

  # Use GDM as the display manager (already enabled in systems/nixos/default.nix)
  # GDM will automatically detect and show Hyprland as a session option

  # Polkit authentication agent will be handled in user config
  security.polkit.enable = true;

  # Environment variables for Wayland
  environment.variables = {
    # Force GTK to use Wayland backend
    GDK_BACKEND = "wayland";

    # Qt Wayland backend
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # XDG session type
    XDG_SESSION_TYPE = "wayland";
  };

  # Required for some Wayland applications
  hardware.graphics.enable = true;
}
