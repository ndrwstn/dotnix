# systems/nixos/desktop/hyprland.nix
# Hyprland configuration for NixOS systems.
{ config
, lib
, ...
}:

lib.mkIf (builtins.elem "hyprland" config._astn.machine.windowManagers) {
  # Hyprland and Wayland support - module handles package and portal automatically.
  programs.hyprland.enable = true;

  # Use GDM as the display manager (enabled in systems/nixos/desktop/default.nix).
  # GDM will automatically detect and show Hyprland as a session option.

  # Environment variables for Wayland.
  environment.variables = {
    # Force GTK to use Wayland backend.
    GDK_BACKEND = "wayland";

    # Qt Wayland backend.
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # XDG session type.
    XDG_SESSION_TYPE = "wayland";
  };
}
