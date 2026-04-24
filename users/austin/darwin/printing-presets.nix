# users/austin/darwin/printing-presets.nix
#
# Wholesale-replace Brother MFC-L8900 printer presets.
#
# Unlike app preferences (see system.nix CustomUserPreferences and
# group-container-prefs.nix), the printer-presets plist is authored entirely
# in Nix. There is no GUI editor whose changes we need to preserve, so
# wholesale ownership is appropriate.
#
# To edit the presets: modify printing-presets.plist directly (it is a
# standard macOS XML plist), or regenerate from a snapshot with
# `plutil -convert xml1 -o printing-presets.plist \
#   ~/Library/Preferences/com.apple.print.custompresets.forprinter.Brother_MFC_L8900.plist`.
{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  home.activation.deployPrinterPresets =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      src=${./printing-presets.plist}
      dst="${config.home.homeDirectory}/Library/Preferences/com.apple.print.custompresets.forprinter.Brother_MFC_L8900.plist"
      if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        chmod 600 "$dst"
        /usr/bin/killall cfprefsd 2>/dev/null || true
        echo "Updated Brother printer presets."
      fi
    '';
}
