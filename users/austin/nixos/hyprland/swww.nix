# users/austin/nixos/hyprland/swww.nix
# swww wallpaper daemon configuration with transitions
{ pkgs, lib, config, ... }:

let
  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers/favorites";

  # Script to rotate wallpapers with matugen theming
  wallpaperRotate = pkgs.writeShellScript "wallpaper-rotate" ''
    set -eu
    
    WALLPAPER_DIR="${wallpaperDir}"
    
    # Check if directory exists and has images
    if [ ! -d "$WALLPAPER_DIR" ]; then
      echo "Wallpaper directory does not exist: $WALLPAPER_DIR"
      exit 0
    fi
    
    # Find a random image
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null | shuf -n 1)
    
    if [ -z "$WALLPAPER" ]; then
      echo "No wallpapers found in $WALLPAPER_DIR"
      exit 0
    fi
    
    # Set wallpaper with swww (fade + slight zoom transition)
    ${pkgs.swww}/bin/swww img "$WALLPAPER" \
      --transition-type grow \
      --transition-pos 0.5,0.5 \
      --transition-duration 1.5 \
      --transition-fps 60 \
      --transition-bezier 0.4,0.0,0.2,1
    
    # Generate colors with matugen
    ${pkgs.matugen}/bin/matugen image "$WALLPAPER" --json > /tmp/matugen-colors.json 2>/dev/null || true
    
    # Apply colors to hyprland (if colors were generated)
    if [ -f /tmp/matugen-colors.json ]; then
      # Source the colors and apply via hyprctl
      # This will be replaced by proper template rendering in later phase
      ${pkgs.hyprland}/bin/hyprctl reload 2>/dev/null || true
    fi
  '';
in
{
  # Systemd user service for wallpaper rotation
  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Rotate wallpapers with dynamic theming";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = wallpaperRotate;
    };
  };

  # Systemd timer for 30-minute rotation
  systemd.user.timers.wallpaper-rotate = {
    Unit = {
      Description = "Rotate wallpaper every 30 minutes";
    };

    Timer = {
      OnBootSec = "1m";
      OnUnitActiveSec = "30m";
      Unit = "wallpaper-rotate.service";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # swww initialization script for exec-once
  home.sessionVariables = {
    # swww configuration
    SWWW_TRANSITION = "grow";
    SWWW_TRANSITION_DURATION = "1.5";
    SWWW_TRANSITION_FPS = "60";
    SWWW_TRANSITION_BEZIER = "0.4,0.0,0.2,1";
    SWWW_TRANSITION_POS = "0.5,0.5";
  };
}
