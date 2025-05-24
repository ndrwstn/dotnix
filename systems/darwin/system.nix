# systems/darwin/system.nix
{ config
, pkgs
, ...
}: {
  # fix for darwin-25.05 needing 'primaryUser' for transition period
  # - probably could just move the following settings to my user flake?
  system.primaryUser = "austin";

  system.defaults = {
    finder = {
      ShowStatusBar = true;
    };
    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.screensaver" = {
        askForPassword = 1;
        # askForPasswordDelay = 0;
      };
    };
  };
}
