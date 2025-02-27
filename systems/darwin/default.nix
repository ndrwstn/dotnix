# Darwin-specific configuration
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
    
    # Common system-wide casks
    casks = [
      "1password"
      "firefox"
      "vlc"
    ];
  };

  # Add homebrew to system PATH
  environment.systemPath = if pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64 then [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ] else [
    "/usr/local/bin"
    "/usr/local/sbin"
  ];

  # System defaults
  system.defaults = {
    dock = {
      tilesize = 16;
    };
    finder = {
      ShowPathbar = true;
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
