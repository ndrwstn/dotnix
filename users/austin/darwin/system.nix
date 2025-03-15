# users/austin/darwin/system.nix
{
  config,
  pkgs,
  ...
}: {
  system = {
    defaults = {
      dock = {
        tilesize = 16;
        persistent-apps = [
          "/System/Applications/Mail.app"
          "/Applications/Across.app"
          "/System/Applications/Calendar.app"
          "/Applications/Things3.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Messages.app"
          "/Applications/Safari.app"
          "/Applications/Neovide.app"
          "/System/Applications/iPhone Mirroring.app"
          "/Applications/Claude.app"
        ];
        persistent-others = [
          "/Users/austin/Downloads"
        ];
      };
      finder = {
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      CustomUserPreferences = {
        "com.apple.finder" = {
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.screensaver" = {
          askForPassword = 1;
          askForPasswordDelay = 10;
        };
      };
    };
  };
}
