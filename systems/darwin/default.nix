# systems/darwin/default.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./homebrew.nix
  ];

  # System defaults
  system.defaults = {
    finder = {
      ShowStatusBar = true;
    };
    customUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.screensaver" = {
        askForPassword = 1;
        askForPasswordDelay = 0;
      };
    };
  };
}
