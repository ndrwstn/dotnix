# users/austin/nixos/hyprland/swww.nix
# swww wallpaper daemon configuration with transitions
{ pkgs, lib, config, ... }:

let
  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers/Favorites";

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
    WALLPAPER=$(${pkgs.findutils}/bin/find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n 1)
    
    if [ -z "$WALLPAPER" ]; then
      echo "No wallpapers found in $WALLPAPER_DIR"
      exit 0
    fi

    # Wait briefly for the swww daemon/socket to be ready
    for _ in $(seq 1 10); do
      if ${pkgs.swww}/bin/swww query >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    if ! ${pkgs.swww}/bin/swww query >/dev/null 2>&1; then
      echo "swww daemon is not ready"
      exit 1
    fi

    # Set wallpaper with swww (fade + slight zoom transition)
    ${pkgs.swww}/bin/swww img "$WALLPAPER" \
      --transition-type grow \
      --transition-pos 0.5,0.5 \
      --transition-duration 1.5 \
      --transition-fps 60 \
      --transition-bezier 0.4,0.0,0.2,1
    
    # Generate colors and app configs with matugen templates
    if ${pkgs.matugen}/bin/matugen image "$WALLPAPER" --config "${config.xdg.configHome}/matugen/config.toml"; then
      # Reload Hyprland only if the generated source file exists
      if [ -s "${config.xdg.cacheHome}/matugen/hyprland-colors.conf" ]; then
        ${pkgs.hyprland}/bin/hyprctl reload 2>/dev/null || true
        systemctl --user restart waybar.service 2>/dev/null || true
      fi
    fi
  '';
in
{
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "swww wallpaper daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Systemd user service for wallpaper rotation
  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Rotate wallpapers with dynamic theming";
      After = [ "graphical-session.target" "swww-daemon.service" ];
      Requires = [ "swww-daemon.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = wallpaperRotate;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Systemd timer for 30-minute rotation
  systemd.user.timers.wallpaper-rotate = {
    Unit = {
      Description = "Rotate wallpaper every 30 minutes";
    };

    Timer = {
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
