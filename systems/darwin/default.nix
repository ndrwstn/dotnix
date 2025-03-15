# systems/darwin/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Get list of active users
  usersDir = ../../users;
  usersList = builtins.attrNames (builtins.readDir usersDir);
  
  # Function to check if a user has a darwin/homebrew.nix file
  hasUserHomebrew = user: 
    builtins.pathExists (usersDir + "/${user}/darwin/homebrew.nix");
  
  # Filter to users that have homebrew configs
  usersWithHomebrew = builtins.filter hasUserHomebrew usersList;
  
  # Import user homebrew configs if they exist and extract the homebrew attribute
  userHomebrewConfigs = map (user: 
    let 
      imported = import (usersDir + "/${user}/darwin/homebrew.nix") {
        inherit config pkgs lib;
      };
    in
      if builtins.hasAttr "homebrew" imported
      then imported.homebrew
      else lib.warn "User ${user}'s homebrew.nix doesn't contain a homebrew attribute" {}
  ) usersWithHomebrew;
  
  # System homebrew config - extract the homebrew attribute
  systemHomebrew = 
    if builtins.pathExists ./homebrew.nix
    then let 
      imported = import ./homebrew.nix { inherit config pkgs lib; };
    in
      if builtins.hasAttr "homebrew" imported
      then [imported.homebrew]
      else lib.warn "System homebrew.nix doesn't contain a homebrew attribute" []
    else [];
  
  # Combine all homebrew configurations
  allHomebrewConfigs = systemHomebrew ++ userHomebrewConfigs;
  
  # Merge all homebrew configurations into a single config
  mergedHomebrewConfig = lib.mkMerge allHomebrewConfigs;
in {
  imports = [
    ./system.nix
  ];

  # Apply the merged Homebrew config directly
  homebrew = mergedHomebrewConfig;

  # System defaults
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