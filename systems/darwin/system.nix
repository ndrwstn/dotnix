# systems/darwin/system.nix
{
  config,
  pkgs,
  ...
}: {
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
        askForPasswordDelay = 0;
      };
    };
  };
}
