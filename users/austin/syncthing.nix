# users/austin/syncthing.nix - Consolidated Syncthing management with JSON secrets
{ config, lib, pkgs, ... }:

let
  # Determine the machine name from hostname or provide a way to override
  machineName =
    if pkgs.stdenv.isDarwin then
      if builtins.pathExists /etc/hostname then
        lib.removeSuffix "\n" (builtins.readFile /etc/hostname)
      else "monaco" # Default for Darwin systems
    else
      if builtins.pathExists /etc/hostname then
        lib.removeSuffix "\n" (builtins.readFile /etc/hostname)
      else "unknown";

  # Path to the JSON secret file (provided by agenix)
  secretPath = "/run/agenix/syncthing-${machineName}";

  # Directory for extracted secrets
  extractDir = "${config.home.homeDirectory}/.config/syncthing-secrets";

  # Machine-specific configuration
  machineConfig = {
    monaco = {
      guiAddress = "127.0.0.1:8384";
      guiPort = 8384;
    };
    plutonium = {
      guiAddress = "127.0.0.1:8385";
      guiPort = 8385;
    };
    siberia = {
      guiAddress = "127.0.0.1:8386";
      guiPort = 8386;
    };
    silver = {
      guiAddress = "127.0.0.1:8387";
      guiPort = 8387;
    };
  };

  # Get configuration for current machine
  currentConfig = machineConfig.${machineName} or machineConfig.monaco;

  # Script to extract JSON secrets to individual files
  extractSecretsScript = pkgs.writeShellScript "extract-syncthing-secrets" ''
    set -euo pipefail
    
    # Check if secret file exists
    if [[ ! -f "${secretPath}" ]]; then
      echo "Warning: Syncthing secret file not found at ${secretPath}"
      echo "Skipping Syncthing secret extraction"
      exit 0
    fi
    
    # Create extraction directory
    mkdir -p "${extractDir}"
    chmod 700 "${extractDir}"
    
    # Extract secrets using jq
    ${pkgs.jq}/bin/jq -r '.deviceId' "${secretPath}" > "${extractDir}/device-id"
    ${pkgs.jq}/bin/jq -r '.cert' "${secretPath}" > "${extractDir}/cert.pem"
    ${pkgs.jq}/bin/jq -r '.key' "${secretPath}" > "${extractDir}/key.pem"
    ${pkgs.jq}/bin/jq -r '.gui.user' "${secretPath}" > "${extractDir}/gui-user"
    ${pkgs.jq}/bin/jq -r '.gui.password' "${secretPath}" > "${extractDir}/gui-password"
    
    # Set appropriate permissions
    chmod 600 "${extractDir}"/*
    
    echo "Syncthing secrets extracted to ${extractDir}"
  '';

in
{
  # Extract secrets during home activation
  home.activation.extractSyncthingSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${extractSecretsScript}
  '';

  # Configure Syncthing service
  services.syncthing = {
    enable = true;

    # GUI settings with machine-specific configuration
    guiAddress = currentConfig.guiAddress;

    # Certificate and key files (extracted from JSON)
    cert = "${extractDir}/cert.pem";
    key = "${extractDir}/key.pem";
  };

  # Create a systemd user service override for NixOS to handle GUI authentication
  systemd.user.services.syncthing = lib.mkIf pkgs.stdenv.isLinux {
    Service = {
      # Ensure secrets are available before starting
      ExecStartPre = "${extractSecretsScript}";
    };
  };

  # Create a helper script for manual secret extraction (useful for debugging)
  home.packages = [
    (pkgs.writeShellScriptBin "syncthing-extract-secrets" ''
      echo "Extracting Syncthing secrets for ${machineName}..."
      ${extractSecretsScript}
      echo "Secrets extracted. Files available in ${extractDir}:"
      ls -la "${extractDir}" 2>/dev/null || echo "No secrets found"
    '')
  ];

  # Ensure the extraction directory exists and has correct permissions
  home.file.".config/syncthing-secrets/.keep" = {
    text = "# This directory contains extracted Syncthing secrets\n";
    onChange = ''
      chmod 700 "${config.home.homeDirectory}/.config/syncthing-secrets"
    '';
  };
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
