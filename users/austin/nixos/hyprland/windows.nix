# users/austin/nixos/hyprland/windows.nix
# Hyprland window rules and behavior configuration
{ pkgs, unstable, lib, config, ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Window rules for Ghostty floating behavior
    # Fixes issue where Ghostty expands to fullscreen when toggled to floating
    # See: Hyprland issues #6648, #7312
    windowrulev2 = [
      # Set default size for Ghostty when floating (80% of screen)
      "size 80% 80%, class:^(ghostty)$, floating:1"
      # Center the window on screen
      "center, class:^(ghostty)$, floating:1"
    ];
  };
}
