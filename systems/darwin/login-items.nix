# systems/darwin/login-items.nix
{ config
, lib
, pkgs
, ...
}: {
  # Configure macOS login items (applications that auto-start on login)
  environment.loginItems = {
    enable = true;
    items = [
      # Productivity launcher - must run for instant hotkey access
      "/Applications/Raycast.app"

      # Future login items can be added here
      # Example:
      # "/Applications/Another-App.app"
    ];
  };
}
