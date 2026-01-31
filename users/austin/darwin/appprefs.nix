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

  acrossPrefsDir = "$HOME/Library/Group Containers/group.com.daymore.Across/Library/Preferences";

  prefScriptFor = item:
    let
      baseScript = plistGen.generateAllPlistScripts {
        inherit config;
        jsonConfig = item.config;
        jsonFilePath = toString item.sourcePath;
      };
      isAcross = item.sourcePath == prefsDir + "/across.json";
    in
    if isAcross then ''
      if [ -d "${acrossPrefsDir}" ]; then
        ${baseScript}
      else
        echo "Across group container not found; skipping prefs" >&2
      fi
    '' else baseScript;

  # Generate deployment script for all preference files
  deploymentScript = lib.concatMapStringsSep "\n"
    prefScriptFor
    prefConfigs;

in
{
  # Only run on Darwin
  home.activation.setupAppPrefs = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Ensure Python is available for batch processing
      export PATH="${pkgs.python3}/bin:$PATH"
      export PLIST_DEPLOY_HEADER_PRINTED=0
      
      ${deploymentScript}
    ''
  );

  # Add warnings if no preference files found
  warnings = lib.optional (builtins.length prefFiles == 0)
    "No preference files found in ${toString prefsDir} - appprefs.nix has nothing to deploy";
}
