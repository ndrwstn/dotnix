# users/austin/nixos/hyprland/awww.nix
# awww wallpaper daemon configuration with transitions
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

    # Wait briefly for the awww daemon/socket to be ready
    for _ in $(seq 1 10); do
      if ${pkgs.awww}/bin/awww query >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    if ! ${pkgs.awww}/bin/awww query >/dev/null 2>&1; then
      echo "awww daemon is not ready"
      exit 1
    fi

    # Set wallpaper with awww (fade + slight zoom transition)
    ${pkgs.awww}/bin/awww img "$WALLPAPER" \
      --transition-type grow \
      --transition-pos 0.5,0.5 \
      --transition-duration 1.5 \
      --transition-fps 60 \
      --transition-bezier 0.4,0.0,0.2,1
    
    # Generate colors and app configs with matugen templates
    if ${pkgs.matugen}/bin/matugen image "$WALLPAPER" \
      --source-color-index 0 \
      --config "${config.xdg.configHome}/matugen/config.toml"; then
      # Reload Hyprland only if the generated source file exists
      if [ -s "${config.xdg.cacheHome}/matugen/hyprland-colors.conf" ]; then
        ${pkgs.hyprland}/bin/hyprctl reload 2>/dev/null || true
        systemctl --user restart waybar.service 2>/dev/null || true
      fi
    fi
  '';
in
{
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  # Systemd user service for wallpaper rotation
  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Rotate wallpapers with dynamic theming";
      After = [ "hyprland-session.target" "awww-daemon.service" ];
      Requires = [ "awww-daemon.service" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = wallpaperRotate;
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  # Systemd timer for 30-minute rotation
  systemd.user.timers.wallpaper-rotate = {
    Unit = {
      Description = "Rotate wallpaper every 30 minutes";
      PartOf = [ "hyprland-session.target" ];
    };

    Timer = {
      OnUnitActiveSec = "30m";
      Unit = "wallpaper-rotate.service";
    };

    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  # awww transition defaults
  home.sessionVariables = {
    # awww configuration
    AWWW_TRANSITION = "grow";
    AWWW_TRANSITION_DURATION = "1.5";
    AWWW_TRANSITION_FPS = "60";
    AWWW_TRANSITION_BEZIER = "0.4,0.0,0.2,1";
    AWWW_TRANSITION_POS = "0.5,0.5";
  };
}
