# systems/darwin/system.nix
{ config
, pkgs
, ...
}: {
  # NOTE: system.primaryUser is set centrally in ./default.nix; setting it
  # here as well would duplicate definitions across discovery layers.

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
