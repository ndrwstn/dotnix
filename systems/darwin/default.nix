# systems/darwin/default.nix
{ config
, pkgs
, lib
, ...
}:
let
  # Import our auto-discovery library
  autoDiscovery = import ../../lib/auto-discovery.nix { inherit lib; };
  
  # Get list of user directories
  usersDir = ../../users;
  
  # Get all user directories
  userDirs = map (user: usersDir + "/${user}") 
    (autoDiscovery.discoverDirectories { 
      basePath = usersDir;
    });
  
  # Discover and merge homebrew configurations
  mergedHomebrewConfig = autoDiscovery.discoverAndMergeConfigs {
    directories = [ ./. ] ++ userDirs;
    filePath = "darwin/homebrew.nix";
    attributeName = "homebrew";
    importArgs = { inherit config pkgs lib; };
  };
  
  # Discover and merge system configurations
  mergedSystemDefaults = autoDiscovery.discoverAndMergeConfigs {
    directories = [ ./. ] ++ userDirs;
    filePath = "darwin/system.nix";
    attributeName = "system";
    importArgs = { inherit config pkgs lib; };
    warnOnMissingAttr = true;
    debug = true;
  };
in
{
  # Import the apps modules
  imports = [
    ./apps
  ];

  # any GUI apps must be added system-wide
  environment.systemPackages = [
    pkgs.neovide
  ];

  # Fix NIX_PATH for darwin systems
  nix.nixPath = [
    "nixpkgs=flake:nixpkgs"
  ];

  # Apply the merged Homebrew config directly
  homebrew = mergedHomebrewConfig;

  # Apply the merged System defaults with primaryUser
  system = lib.mkMerge [
    mergedSystemDefaults
    { primaryUser = "austin"; }
  ];
}
