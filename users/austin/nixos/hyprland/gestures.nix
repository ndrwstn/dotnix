# Gesture support for Hyprland
# Note: These gestures are enabled for all NixOS systems. For systems without
# trackpads or gesture input devices, consider conditionally enabling this
# module based on hardware detection or system type.
{ pkgs, lib, ... }:

{
  wayland.windowManager.hyprland = {
    # Append gesture configurations to hyprland.conf
    extraConfig = lib.concatStringsSep "\n" [
      "# Trackpad gestures - workspace and window management"
      "gesture = 3, horizontal, workspace"
      "gesture = 3, vertical, move"

      "# 4-finger gestures - common actions"
      "gesture = 4, left, dispatcher, exec, ${pkgs.kitty}/bin/kitty"
      "gesture = 4, up, close"
      "gesture = 4, right, float"
      "gesture = 4, down, fullscreen"

      "# 2-finger pinch gestures (uncomment and customize as needed)"
      "# gesture = 2, pinchout, dispatcher, exec, ~/.config/hypr/gestures/zoom-in.sh"
      "# gesture = 2, pinchin,  dispatcher, exec, ~/.config/hypr/gestures/zoom-out.sh"

      "# Example modifier-guarded gesture (uncomment to enable)"
      "# gesture = 3, left, mod: ALT, move"
    ];
  };
}
