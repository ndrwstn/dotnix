# users/austin/syncthing.nix - Declarative Syncthing configuration with shared secrets
{ config, lib, pkgs, hostName ? "unknown", ... }:

let
  # Use the hostName parameter passed from flake, normalize to lowercase
  machineName = lib.toLower hostName;

  # Path to the JSON secret files (provided by agenix)
  secretPath = "/run/agenix/syncthing-${machineName}";
  sharedSecretPath = "/run/agenix/syncthing";

  # Directory for extracted secrets
  extractDir = "${config.home.homeDirectory}/.config/syncthing-secrets";

  # Note: Shared configuration will be read at runtime via activation script
  # Cannot use builtins.pathExists/readFile as they evaluate at build time
  # when /run/agenix/syncthing doesn't exist yet

  # Machine-specific configuration
  machineConfigs = {
    monaco = {
      guiAddress = "127.0.0.1:8384";
      guiPort = 8384;
      compression = "metadata";
    };
    plutonium = {
      guiAddress = "127.0.0.1:8385";
      guiPort = 8385;
      compression = "metadata";
    };
    siberia = {
      guiAddress = "127.0.0.1:8386";
      guiPort = 8386;
      compression = "metadata";
    };
    silver = {
      guiAddress = "127.0.0.1:8387";
      guiPort = 8387;
      compression = "metadata";
    };
  };



  # Check if current machine is configured
  isMachineConfigured = machineConfigs ? ${machineName};

  # Get configuration for current machine (only if configured)
  currentConfig = if isMachineConfigured then machineConfigs.${machineName} else null;

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

  # Script to set GUI username using syncthing generate
  setGuiUserScript = pkgs.writeShellScript "set-syncthing-gui-user" ''
    set -euo pipefail
    
    # Check if gui-user file exists
    if [[ ! -f "${extractDir}/gui-user" ]]; then
      echo "Warning: GUI user file not found at ${extractDir}/gui-user"
      exit 0
    fi
    
    # Read the username
    GUI_USER=$(cat "${extractDir}/gui-user")
    
    # Set the GUI user using syncthing generate
    ${pkgs.syncthing}/bin/syncthing generate --gui-user="$GUI_USER"
    
    echo "Set Syncthing GUI user to: $GUI_USER"
  '';

  # Script to update syncthing configuration from shared secret at runtime
  updateSyncthingConfigScript = pkgs.writeShellScript "update-syncthing-config" ''
    set -euo pipefail
    
    # Check if shared secret exists
    if [[ ! -f "${sharedSecretPath}" ]]; then
      echo "Shared syncthing secret not found at ${sharedSecretPath}"
      echo "Syncthing will run with certificate-based identity only"
      exit 0
    fi
    
    # Wait for syncthing to be available (up to 30 seconds)
    echo "Waiting for Syncthing API to be available..."
    for i in {1..30}; do
      if ${pkgs.curl}/bin/curl -s "127.0.0.1:${toString currentConfig.guiPort}/rest/system/ping" >/dev/null 2>&1; then
        echo "Syncthing API is available"
        break
      fi
      if [[ $i -eq 30 ]]; then
        echo "Timeout waiting for Syncthing API"
        exit 1
      fi
      sleep 1
    done
    
    # Read shared configuration
    SHARED_CONFIG=$(cat "${sharedSecretPath}")
    
    # Extract device IDs
    MONACO_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.devices.monaco // empty')
    SILVER_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.devices.silver // empty')
    
    # Get API key
    API_KEY=$(${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' \
      "${config.home.homeDirectory}/.local/state/syncthing/config.xml" 2>/dev/null || \
      ${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' \
      "${config.home.homeDirectory}/Library/Application Support/Syncthing/config.xml" 2>/dev/null || \
      echo "")
    
    if [[ -z "$API_KEY" ]]; then
      echo "Could not retrieve Syncthing API key"
      exit 1
    fi
    
    # Update devices via REST API (only add devices for other machines)
    if [[ "${machineName}" != "monaco" && -n "$MONACO_ID" ]]; then
      echo "Adding Monaco device: $MONACO_ID"
      ${pkgs.curl}/bin/curl -X POST \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"deviceID\":\"$MONACO_ID\",\"name\":\"Monaco\",\"addresses\":[\"dynamic\"],\"compression\":\"metadata\",\"autoAcceptFolders\":false}" \
        "127.0.0.1:${toString currentConfig.guiPort}/rest/config/devices"
    fi
    
    if [[ "${machineName}" != "silver" && -n "$SILVER_ID" ]]; then
      echo "Adding Silver device: $SILVER_ID"
      ${pkgs.curl}/bin/curl -X POST \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"deviceID\":\"$SILVER_ID\",\"name\":\"Silver\",\"addresses\":[\"dynamic\"],\"compression\":\"metadata\",\"autoAcceptFolders\":false}" \
        "127.0.0.1:${toString currentConfig.guiPort}/rest/config/devices"
    fi
    
    # Add test folder if both devices are available
    if [[ -n "$MONACO_ID" && -n "$SILVER_ID" ]]; then
      echo "Adding test folder configuration"
      FOLDER_DEVICES="[]"
      if [[ "${machineName}" != "monaco" ]]; then
        FOLDER_DEVICES=$(echo "$FOLDER_DEVICES" | ${pkgs.jq}/bin/jq ". + [{\"deviceID\":\"$MONACO_ID\"}]")
      fi
      if [[ "${machineName}" != "silver" ]]; then
        FOLDER_DEVICES=$(echo "$FOLDER_DEVICES" | ${pkgs.jq}/bin/jq ". + [{\"deviceID\":\"$SILVER_ID\"}]")
      fi
      
      ${pkgs.curl}/bin/curl -X POST \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"id\":\"nix-sync-test\",\"path\":\"${config.home.homeDirectory}/nix-syncthing\",\"devices\":$FOLDER_DEVICES,\"type\":\"sendreceive\",\"fsWatcherEnabled\":true,\"fsWatcherDelayS\":10,\"rescanIntervalS\":180,\"ignorePerms\":true}" \
        "127.0.0.1:${toString currentConfig.guiPort}/rest/config/folders"
    fi
    
    echo "Syncthing configuration updated from shared secret"
  '';

  # Device and folder configuration now handled at runtime via REST API

  # Global Syncthing options
  syncthingGlobalOptions = {
    urAccepted = -1; # Disable usage reporting
    relaysEnabled = false; # Local only
    localAnnounceEnabled = true;
    globalAnnounceEnabled = false;
    natEnabled = false;
  };

  # Script to create test files and .stignore
  createTestFilesScript = pkgs.writeShellScript "create-syncthing-test-files" ''
        set -euo pipefail
    
        # Create test directory
        TEST_DIR="${config.home.homeDirectory}/nix-syncthing"
        mkdir -p "$TEST_DIR"
    
        # Generate timestamp and hostname at runtime
        TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
        HOSTNAME=$(hostname -s)
    
        # Create test file with machine info
        TEST_FILE="$TEST_DIR/test-${machineName}-$TIMESTAMP-$HOSTNAME.txt"
        cat > "$TEST_FILE" << EOF
    # Syncthing Test File
    Machine: ${machineName}
    Hostname: $HOSTNAME
    Created: $(date '+%Y-%m-%d %H:%M:%S')
    User: ${config.home.username}

    This file was created automatically during home-manager activation
    to test the syncthing configuration on ${machineName}.
    EOF
    
        # Create .stignore file with macOS hidden file patterns
        cat > "$TEST_DIR/.stignore" << 'EOF'
    # macOS hidden files and metadata
    .DS_Store
    ._*
    .Spotlight-V100
    .Trashes
    .fseventsd
    .TemporaryItems
    .VolumeIcon.icns

    # Temporary files
    *.tmp
    *.temp
    *~
    .#*

    # Version control
    .git
    .svn
    .hg

    # IDE files
    .vscode
    .idea
    *.swp
    *.swo

    # OS generated files
    Thumbs.db
    desktop.ini
    EOF
    
        echo "Created test file: $TEST_FILE"
        echo "Created .stignore file: $TEST_DIR/.stignore"
  '';

in
{
  # Only configure Syncthing if machine is in the configured list
  # Extract secrets during home activation
  home.activation.extractSyncthingSecrets = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${extractSecretsScript}
  '');

  # Set GUI username during home activation
  home.activation.setSyncthingGuiUser = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "extractSyncthingSecrets" ] ''
    $DRY_RUN_CMD ${setGuiUserScript}
  '');

  # Create test files during home activation
  home.activation.createSyncthingTestFiles = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${createTestFilesScript}
  '');

  # Update syncthing configuration from shared secret after service starts
  home.activation.updateSyncthingConfig = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    # Run in background to avoid blocking activation
    (${updateSyncthingConfigScript} &)
  '');

  # Configure Syncthing service (devices/folders managed via runtime REST API)
  services.syncthing = lib.mkIf isMachineConfigured {
    enable = true;
    guiAddress = "127.0.0.1:${toString currentConfig.guiPort}";
    passwordFile = "${extractDir}/gui-password";

    # Don't override devices/folders - managed via REST API at runtime
    overrideDevices = false;
    overrideFolders = false;

    settings = {
      options = syncthingGlobalOptions;
    };
  };

  # Create a systemd user service override for NixOS to handle GUI authentication
  systemd.user.services.syncthing = lib.mkIf (isMachineConfigured && pkgs.stdenv.isLinux) {
    Service = {
      # Ensure secrets are available before starting
      ExecStartPre = lib.mkForce "${extractSecretsScript}";
    };
  };

  # Create a helper script for manual secret extraction (useful for debugging)
  home.packages = lib.mkIf isMachineConfigured [
    (pkgs.writeShellScriptBin "syncthing-extract-secrets" ''
      echo "Extracting Syncthing secrets for ${machineName}..."
      ${extractSecretsScript}
      echo "Secrets extracted. Files available in ${extractDir}:"
      ls -la "${extractDir}" 2>/dev/null || echo "No secrets found"
    '')
    (pkgs.writeShellScriptBin "syncthing-create-test-files" ''
      echo "Creating Syncthing test files for ${machineName}..."
      ${createTestFilesScript}
      echo "Test files created in ${config.home.homeDirectory}/nix-syncthing"
    '')
  ];

  # Ensure the extraction directory exists and has correct permissions
  home.file.".config/syncthing-secrets/.keep" = lib.mkIf isMachineConfigured {
    text = "# This directory contains extracted Syncthing secrets\n";
    onChange = ''
      chmod 700 "${config.home.homeDirectory}/.config/syncthing-secrets"
    '';
  };

  # Smart certificate deployment for Darwin using activation scripts
  home.activation.deploySyncthingCertificates = lib.mkIf (isMachineConfigured && pkgs.stdenv.isDarwin) (
    lib.hm.dag.entryAfter [ "extractSyncthingSecrets" ] ''
      $DRY_RUN_CMD ${pkgs.writeShellScript "deploy-syncthing-certificates" ''
        set -euo pipefail
        
        SYNCTHING_DIR="$HOME/Library/Application Support/Syncthing"
        
        # Check if certificates need updating
        NEEDS_UPDATE=0
        
        if [[ -f "$SYNCTHING_DIR/cert.pem" ]] && /usr/bin/cmp -s "${extractDir}/cert.pem" "$SYNCTHING_DIR/cert.pem"; then
          echo "Certificate is up-to-date"
        else
          echo "Certificate needs updating"
          NEEDS_UPDATE=1
        fi
        
        if [[ -f "$SYNCTHING_DIR/key.pem" ]] && /usr/bin/cmp -s "${extractDir}/key.pem" "$SYNCTHING_DIR/key.pem"; then
          echo "Private key is up-to-date"
        else
          echo "Private key needs updating"
          NEEDS_UPDATE=1
        fi
        
        # Only restart if certificates actually changed
        if [[ $NEEDS_UPDATE -eq 1 ]]; then
          echo "Deploying new Syncthing certificates..."
          
          # Check if syncthing is running
          SYNCTHING_WAS_RUNNING=0
          if /bin/launchctl list | grep -q org.nix-community.home.syncthing; then
            SYNCTHING_WAS_RUNNING=1
            echo "Stopping Syncthing service..."
            /bin/launchctl stop org.nix-community.home.syncthing 2>/dev/null || true
            sleep 2
          fi
          
          # Deploy certificates (remove existing files first to avoid permission issues)
          mkdir -p "$SYNCTHING_DIR"
          rm -f "$SYNCTHING_DIR/cert.pem" "$SYNCTHING_DIR/key.pem"
          cp "${extractDir}/cert.pem" "$SYNCTHING_DIR/cert.pem"
          cp "${extractDir}/key.pem" "$SYNCTHING_DIR/key.pem"
          chmod 400 "$SYNCTHING_DIR/cert.pem"
          chmod 400 "$SYNCTHING_DIR/key.pem"
          
          # Restart syncthing if it was running
          if [[ $SYNCTHING_WAS_RUNNING -eq 1 ]]; then
            echo "Starting Syncthing service..."
            /bin/launchctl start org.nix-community.home.syncthing 2>/dev/null || true
            echo "Syncthing restarted with new certificates"
          else
            echo "Syncthing was not running, certificates will be used on next start"
          fi
        else
          echo "Syncthing certificates are up-to-date, no restart needed"
        fi
      ''}
    ''
  );

  # Smart certificate deployment for NixOS using activation scripts
  home.activation.deploySyncthingCertificatesLinux = lib.mkIf (isMachineConfigured && pkgs.stdenv.isLinux) (
    lib.hm.dag.entryAfter [ "extractSyncthingSecrets" ] ''
      $DRY_RUN_CMD ${pkgs.writeShellScript "deploy-syncthing-certificates-linux" ''
        set -euo pipefail
        
        SYNCTHING_DIR="$HOME/.local/state/syncthing"
        
        # Check if certificates need updating
        NEEDS_UPDATE=0
        
        if [[ -f "$SYNCTHING_DIR/cert.pem" ]] && ${pkgs.diffutils}/bin/cmp -s "${extractDir}/cert.pem" "$SYNCTHING_DIR/cert.pem"; then
          echo "Certificate is up-to-date"
        else
          echo "Certificate needs updating"
          NEEDS_UPDATE=1
        fi
        
        if [[ -f "$SYNCTHING_DIR/key.pem" ]] && ${pkgs.diffutils}/bin/cmp -s "${extractDir}/key.pem" "$SYNCTHING_DIR/key.pem"; then
          echo "Private key needs updating"
          NEEDS_UPDATE=1
        fi
        
        # Only restart if certificates actually changed
        if [[ $NEEDS_UPDATE -eq 1 ]]; then
          echo "Deploying new Syncthing certificates..."
          
          # Check if syncthing is running
          SYNCTHING_WAS_RUNNING=0
          if ${pkgs.systemd}/bin/systemctl --user is-active syncthing.service >/dev/null 2>&1; then
            SYNCTHING_WAS_RUNNING=1
            echo "Stopping Syncthing service..."
            ${pkgs.systemd}/bin/systemctl --user stop syncthing.service 2>/dev/null || true
            sleep 2
          fi
          
          # Deploy certificates (remove existing files first to avoid permission issues)
          mkdir -p "$SYNCTHING_DIR"
          rm -f "$SYNCTHING_DIR/cert.pem" "$SYNCTHING_DIR/key.pem"
          cp "${extractDir}/cert.pem" "$SYNCTHING_DIR/cert.pem"
          cp "${extractDir}/key.pem" "$SYNCTHING_DIR/key.pem"
          chmod 400 "$SYNCTHING_DIR/cert.pem"
          chmod 400 "$SYNCTHING_DIR/key.pem"
          
          # Restart syncthing if it was running
          if [[ $SYNCTHING_WAS_RUNNING -eq 1 ]]; then
            echo "Starting Syncthing service..."
            ${pkgs.systemd}/bin/systemctl --user start syncthing.service 2>/dev/null || true
            echo "Syncthing restarted with new certificates"
          else
            echo "Syncthing was not running, certificates will be used on next start"
          fi
        else
          echo "Syncthing certificates are up-to-date, no restart needed"
        fi
      ''}
    ''
  );

  # Warning messages
  warnings = lib.optional (!isMachineConfigured)
    "Syncthing is disabled for machine '${machineName}' - not found in configured devices: ${lib.concatStringsSep ", " (lib.attrNames machineConfigs)}";
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
