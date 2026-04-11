# users/austin/nixos/vicinae.nix
# Vicinae launcher configuration (Raycast-like for Linux)
{ config
, pkgs
, lib
, ...
}: {
  programs.vicinae = {
    enable = true;

    # Vicinae runs as a systemd user service for instant response
    # (like Raycast on macOS)
    #
    # The service is automatically managed by the home-manager module:
    # - Starts with graphical-session.target
    # - Restarts automatically on failure
    # - Provides the daemon for launcher/clipboard commands
    #
    # Settings can be added here when needed:
    # settings = {
    #   # Custom configuration options
    # };
  };
}
