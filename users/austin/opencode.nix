# users/austin/opencode.nix - OpenCode authentication configuration
{ config, lib, pkgs, ... }:

let
  # Path to the JSON secret file (provided by agenix)
  secretPath = "/run/agenix/opencode";

  # Directory for OpenCode authentication
  opencodeDir = "${config.xdg.dataHome}/opencode";

  # Setup script to extract OpenCode authentication
  setupOpencodeScript = pkgs.writeShellScript "setup-opencode" ''
    set -euo pipefail

    echo "Setting up OpenCode authentication"

    # Check if secret file exists
    if [[ ! -f "${secretPath}" ]]; then
      echo "Warning: OpenCode secret file not found at ${secretPath}"
      echo "Skipping OpenCode configuration"
      exit 0
    fi

    # Ensure OpenCode directory exists
    mkdir -p "${opencodeDir}"
    chmod 700 "${opencodeDir}"

    # Copy the JSON secret to the OpenCode directory
    cp "${secretPath}" "${opencodeDir}/auth.json"

    # Set appropriate permissions
    chmod 600 "${opencodeDir}/auth.json"

    echo "OpenCode authentication setup complete"
  '';

in
{
  # Setup activation script - runs after writeBoundary
  home.activation.setupOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupOpencodeScript}
  '';
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
