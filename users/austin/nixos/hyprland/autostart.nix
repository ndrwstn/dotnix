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
    # Polkit authentication agent
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

    # 1Password (already configured in systems/nixos/1password.nix)
    "systemctl --user start 1password"

    # Set background wallpaper using swww
    "${pkgs.swww}/bin/swww init"
    "${pkgs.swww}/bin/swww img ~/.wallpaper.jpg"

    # Set cursor theme
    "hyprctl setcursor breeze_cursors 24"

    # Enable screen locking on idle
    "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${pkgs.swaylock}/bin/swaylock -f'"
  ];
}
