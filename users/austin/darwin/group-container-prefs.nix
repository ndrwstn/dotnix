# users/austin/darwin/group-container-prefs.nix
#
# Per-key preference writer for plists whose paths are not addressable by
# nix-darwin's `system.defaults.CustomUserPreferences` — namely Group
# Container plists under ~/Library/Group Containers/<group>/Library/...
#
# Declare only the keys you actually want pinned. Unmanaged keys are left
# alone so the app's own state (window positions, recent items, etc.) is
# preserved across rebuilds.
#
# Usage:
#
#   plistKeys = {
#     "${config.home.homeDirectory}/Library/Group Containers/group.com.example/Library/Preferences/group.com.example.plist" = {
#       "Settings.featureFlag" = true;
#       "Settings.maxItems" = 20;
#       "Settings.greeting" = "hello";
#     };
#   };
#
# Scalar values (bool/int/float/string) are supported via `defaults write`
# with inferred type flags. If you need to pin an array or dict value, add
# handling here when the first case arises.
{ config, lib, pkgs, ... }:

let
  # Per-user declaration of path → { key = value; } to pin.
  # Leave empty until you know which keys you want to pin — anything in the
  # live plist that isn't listed here stays under the app's control.
  plistKeys = {
    # Example (uncomment and edit when adding keys):
    # "${config.home.homeDirectory}/Library/Group Containers/group.com.daymore.Across/Library/Preferences/group.com.daymore.Across.plist" = {
    #   "App.premium" = true;
    # };
  };

  # Render one `defaults write` invocation for a single key/value pair.
  writeKey = plistPath: key: value:
    let
      escapedKey = lib.escapeShellArg key;
      escapedPath = lib.escapeShellArg plistPath;
      typeAndValue =
        if lib.isBool value then "-bool ${if value then "true" else "false"}"
        else if lib.isInt value then "-int ${toString value}"
        else if lib.isFloat value then "-float ${toString value}"
        else if lib.isString value then "-string ${lib.escapeShellArg value}"
        else throw "group-container-prefs: unsupported value type for key ${key} at ${plistPath}";
    in
    "/usr/bin/defaults write ${escapedPath} ${escapedKey} ${typeAndValue}";

  # Render all writes for a single plist path, guarded by parent-dir existence
  # (so sandbox containers that haven't been created yet are skipped rather
  # than causing a spurious error).
  writesForPath = plistPath: keys:
    let
      parentDir = builtins.dirOf plistPath;
      lines = lib.mapAttrsToList (writeKey plistPath) keys;
    in
    ''
      if [ -d ${lib.escapeShellArg parentDir} ]; then
        ${lib.concatStringsSep "\n        " lines}
      fi
    '';

  script = lib.concatStringsSep "\n" (lib.mapAttrsToList writesForPath plistKeys);

in
lib.mkIf (pkgs.stdenv.isDarwin && plistKeys != { }) {
  home.activation.setupGroupContainerPrefs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] script;
}
