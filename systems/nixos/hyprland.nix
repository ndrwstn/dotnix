# systems/nixos/hyprland.nix
# Hyprland configuration for NixOS systems
{ pkgs, ... }:

{
  # Enable Hyprland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # For X11 applications
  };

  # Display manager - greetd for Hyprland session
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland --cmd GNOME";
        user = "greeter";
      };
    };
  };

  # Polkit authentication will be configured in user home-manager

  # Notification daemon will be configured in user home-manager

  # XDG Desktop Portal for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Environment variables for Wayland
  environment.variables = {
    # Force GTK apps to use Wayland
    GDK_BACKEND = "wayland";
    # Qt Wayland support
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # SDL Wayland support
    SDL_VIDEODRIVER = "wayland";
    # XDG Session type
    XDG_SESSION_TYPE = "wayland";
    # Cursor theme for Wayland
    XCURSOR_THEME = "breeze_cursors";
    XCURSOR_SIZE = "24";
  };

  # Additional Wayland utilities
  environment.systemPackages = with pkgs; [
    # Clipboard support
    wl-clipboard
    # Screenshot tool
    grim
    # Screen area selection
    slurp
    # Screen locker
    swaylock
    # Idle management
    swayidle
  ];

  # Swayidle configuration for screen locking
  systemd.user.services.swayidle = {
    description = "Swayidle - Idle management daemon";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${pkgs.swaylock}/bin/swaylock -f'";
      Restart = "on-failure";
    };
  };
}
