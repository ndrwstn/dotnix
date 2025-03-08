# systems/darwin/default.nix
{ config, pkgs, lib, ... }:

{
  # System-wide Homebrew configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
    };
  };

  # Add homebrew to system PATH
  environment.systemPath = if pkgs.stdenv.isAarch64 then [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ] else [
    "/usr/local/bin"
    "/usr/local/sbin"
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
