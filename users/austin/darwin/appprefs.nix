# users/austin/darwin/appprefs.nix
{ config, lib, pkgs, ... }:

let
  # Import plist generator library
  plistGen = import ../../../lib/plist-generator.nix { inherit lib pkgs; };

  # Directory containing preference JSON files
  prefsDir = ./prefs;

  # Discover all JSON files in prefs directory
  prefFiles = builtins.attrNames (
    lib.filterAttrs
      (name: type: type == "regular" && lib.hasSuffix ".json" name)
      (builtins.readDir prefsDir)
  );

  # Load and parse each JSON file, tracking source paths
  prefConfigs = map
    (filename: {
      config = builtins.fromJSON (builtins.readFile (prefsDir + "/${filename}"));
      sourcePath = prefsDir + "/${filename}";
    })
    prefFiles;

  # Generate deployment script for all preference files
  deploymentScript = lib.concatMapStringsSep "\n"
    (item:
      plistGen.generateAllPlistScripts {
        inherit config;
        jsonConfig = item.config;
        jsonFilePath = toString item.sourcePath;
      }
    )
    prefConfigs;

in
{
  # Only run on Darwin
  home.activation.setupAppPrefs = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Ensure Python is available for batch processing
      export PATH="${pkgs.python3}/bin:$PATH"
      
      ${deploymentScript}
    ''
  );

  # Add warnings if no preference files found
  warnings = lib.optional (builtins.length prefFiles == 0)
    "No preference files found in ${toString prefsDir} - appprefs.nix has nothing to deploy";
}
