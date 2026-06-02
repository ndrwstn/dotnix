# users/austin/nixos/hyprland/windows.nix
# Hyprland window rules and behavior configuration
{ pkgs, unstable, lib, config, ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Window rules for Ghostty floating behavior
    # Fixes issue where Ghostty expands to fullscreen when toggled to floating
    # See: Hyprland issues #6648, #7312
    # Uses hyprland 0.55+ inline syntax
    windowrule = [
      # Float at 80% size, centered
      "match:class ^(ghostty)$, float on, size 80% 80%, center on"
    ];
  };
}
