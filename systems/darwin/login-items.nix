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
      "/Applications/Raycast.app"
      "/Applications/Moom.app"
      "/Applications/Ice.app"
      "/Applications/Little Snitch.app"
      "/Applications/logioptionsplus.app"
      "/Applications/Amphetamine.app"

      # Future consideration:
      # "/Applications/Dropbox.app"
      # "/Applications/Google Drive.app"
      # "/Applications/MEGAsync.app"
      # "/Applications/MonitorControl.app"
      # "/Applications/Carbon Copy Cloner.app"
      # "/Applications/Dropzone 4.app"
      # "/Applications/Hazel.app"
      # "/Applications/SnippetsLab.app"
    ];
  };
}
