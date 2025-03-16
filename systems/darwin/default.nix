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

  # Function to check if a user has darwin config files
  hasUserHomebrew = user:
    builtins.pathExists (usersDir + "/${user}/darwin/homebrew.nix");

  hasUserSystem = user:
    builtins.pathExists (usersDir + "/${user}/darwin/system.nix");

  # Filter to users that have configs
  usersWithHomebrew = builtins.filter hasUserHomebrew usersList;
  usersWithSystem = builtins.filter hasUserSystem usersList;

  # Import user homebrew configs if they exist and extract the homebrew attribute
  userHomebrewConfigs =
    map (
      user: let
        imported = import (usersDir + "/${user}/darwin/homebrew.nix") {
          inherit config pkgs lib;
        };
      in
        if builtins.hasAttr "homebrew" imported
        then imported.homebrew
        else lib.warn "User ${user}'s homebrew.nix doesn't contain a homebrew attribute" {}
    )
    usersWithHomebrew;

  # Import user system configs if they exist and extract the system attribute
  userSystemConfigs =
    map (
      user: let
        imported = import (usersDir + "/${user}/darwin/system.nix") {
          inherit config pkgs lib;
        };
      in
        if builtins.hasAttr "system" imported
        then imported.system
        else lib.warn "User ${user}'s system.nix doesn't contain a system attribute" {}
    )
    usersWithSystem;

  # System configs - extract the relevant attributes
  systemHomebrew =
    if builtins.pathExists ./homebrew.nix
    then let
      imported = import ./homebrew.nix {inherit config pkgs lib;};
    in
      if builtins.hasAttr "homebrew" imported
      then [imported.homebrew]
      else lib.warn "System homebrew.nix doesn't contain a homebrew attribute" []
    else [];

  systemDefaults =
    if builtins.pathExists ./system.nix
    then let
      imported = import ./system.nix {inherit config pkgs lib;};
    in
      if builtins.hasAttr "system" imported
      then [imported.system]
      else lib.warn "System system.nix doesn't contain a system attribute" []
    else [];

  # Combine all configurations
  allHomebrewConfigs = systemHomebrew ++ userHomebrewConfigs;
  allSystemConfigs = systemDefaults ++ userSystemConfigs;

  # Merge all configurations into single configs
  mergedHomebrewConfig = lib.mkMerge allHomebrewConfigs;
  mergedSystemConfig = lib.mkMerge allSystemConfigs;
in {
  # Import the apps modules
  imports = [
    ./apps
  ];

  # Apply the merged Homebrew config directly
  homebrew = mergedHomebrewConfig;

  # Apply the merged System config directly
  system = mergedSystemConfig;
}
