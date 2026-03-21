# users/austin/clamav.nix
# User-level ClamAV configuration with auto-update wrapper
{ config
, pkgs
, lib
, ...
}:
let
  # Wrapper script that auto-updates ClamAV DB if missing or stale
  clamscanWrapper = pkgs.writeShellScriptBin "clamscan" ''
    #!${pkgs.bash}/bin/bash

    DB_DIR="$HOME/.local/share/clamav"
    FRESHCLAM="${pkgs.clamav}/bin/freshclam"
    CLAMSCAN="${pkgs.clamav}/bin/clamscan"

    # Ensure DB directory exists
    mkdir -p "$DB_DIR"

    # Check if database exists and is not stale (>24 hours)
    needs_update=false

    if [ ! -f "$DB_DIR/main.cvd" ] && [ ! -f "$DB_DIR/main.cld" ]; then
      echo "ClamAV database not found. Running freshclam to download..."
      needs_update=true
    elif [ -n "$(find "$DB_DIR" -name 'main.cvd' -mtime +1 -print -quit 2>/dev/null)" ] || \
         [ -n "$(find "$DB_DIR" -name 'main.cld' -mtime +1 -print -quit 2>/dev/null)" ]; then
      echo "ClamAV database is older than 24 hours. Running freshclam to update..."
      needs_update=true
    fi

    if [ "$needs_update" = true ]; then
      $FRESHCLAM --config-file=/etc/clamav/freshclam.conf
      if [ $? -ne 0 ]; then
        echo "Warning: freshclam failed, but continuing with scan..."
      fi
    fi

    # Run actual clamscan with all provided arguments
    exec $CLAMSCAN "$@"
  '';
in
{
  # Add the wrapper script to home packages
  home.packages = [ clamscanWrapper ];

  # Add shell alias for manual freshclam
  programs.zsh.shellAliases = {
    freshclam = "${pkgs.clamav}/bin/freshclam --config-file=/etc/clamav/freshclam.conf";
  };
}
