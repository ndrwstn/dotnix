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
    
    # Function to stop Syncthing on error
    stop_syncthing() {
      echo "Stopping Syncthing to prevent inconsistent state"
      if [[ "${toString pkgs.stdenv.isLinux}" == "1" ]]; then
        ${pkgs.systemd}/bin/systemctl --user stop syncthing.service || true
      else
        /bin/launchctl stop org.nix-community.home.syncthing 2>/dev/null || true
      fi
      echo "WARNING: Syncthing has been stopped due to configuration error"
      echo "Please check the logs and rebuild to retry"
    }
    
    # Function to make API calls with error handling
    call_api() {
      local method=$1
      local endpoint=$2
      local data=$3
      
      RESPONSE=$(${pkgs.curl}/bin/curl -s -w '\n%{http_code}' -X "$method" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        ''${data:+-d "$data"} \
        "127.0.0.1:${toString currentConfig.guiPort}$endpoint")
      
      HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
      BODY=$(echo "$RESPONSE" | head -n-1)
      
      if [[ "$HTTP_CODE" != "200" ]] && [[ "$HTTP_CODE" != "204" ]]; then
        echo "ERROR: API call failed (HTTP $HTTP_CODE): $BODY"
        stop_syncthing
        exit 1
      fi
      
      echo "$BODY"
    }
    
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
        exit 0  # Don't fail activation, just skip configuration
      fi
      sleep 1
    done
    
    # Wait for config.xml to be created (up to 60 seconds)
    echo "Waiting for Syncthing config.xml to be created..."
    API_KEY=""
    for i in {1..60}; do
      CONFIG_FILE=""
      if [[ -d "${config.home.homeDirectory}/.local/state/syncthing" ]]; then
        CONFIG_FILE="${config.home.homeDirectory}/.local/state/syncthing/config.xml"
      elif [[ -d "${config.home.homeDirectory}/Library/Application Support/Syncthing" ]]; then
        CONFIG_FILE="${config.home.homeDirectory}/Library/Application Support/Syncthing/config.xml"
      fi
      
      if [[ -f "$CONFIG_FILE" ]]; then
        API_KEY=$(${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' "$CONFIG_FILE" 2>/dev/null || true)
        if [[ -n "$API_KEY" ]]; then
          echo "Successfully retrieved API key from $CONFIG_FILE"
          break
        fi
      fi
      
      if [[ $i -eq 60 ]]; then
        echo "Timeout waiting for Syncthing config.xml after 60 seconds"
        echo "You may need to rebuild a second time after Syncthing initializes"
        exit 0  # Don't fail activation, just skip configuration
      fi
      sleep 1
    done
    
    # Read and validate shared configuration
    SHARED_CONFIG=$(cat "${sharedSecretPath}")
    
    # Validate JSON structure
    if ! echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -e '.devices' >/dev/null 2>&1; then
      echo "ERROR: Invalid shared secret JSON structure - missing devices"
      stop_syncthing
      exit 1
    fi
    
    # Extract device IDs
    MONACO_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.devices.monaco // empty')
    SILVER_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.devices.silver // empty')
    
    echo "Starting declarative Syncthing configuration..."
    echo "Monaco ID: $MONACO_ID"
    echo "Silver ID: $SILVER_ID"
    
    # Get current configuration to override everything
    echo "Retrieving current Syncthing configuration..."
    CURRENT_DEVICES=$(call_api GET "/rest/config/devices" "")
    CURRENT_FOLDERS=$(call_api GET "/rest/config/folders" "")
    
    # DELETE all existing devices (except self)
    echo "Removing all existing devices..."
    echo "$CURRENT_DEVICES" | ${pkgs.jq}/bin/jq -r '.[] | select(.deviceID != "self") | .deviceID' | while read -r DEVICE_ID; do
      if [[ -n "$DEVICE_ID" ]]; then
        echo "Removing existing device: $DEVICE_ID"
        call_api DELETE "/rest/config/devices/$DEVICE_ID" "" >/dev/null
      fi
    done
    
    # DELETE all existing folders (except default)
    echo "Removing all existing folders..."
    echo "$CURRENT_FOLDERS" | ${pkgs.jq}/bin/jq -r '.[] | select(.id != "default") | .id' | while read -r FOLDER_ID; do
      if [[ -n "$FOLDER_ID" ]]; then
        echo "Removing existing folder: $FOLDER_ID"
        call_api DELETE "/rest/config/folders/$FOLDER_ID" "" >/dev/null
      fi
    done
    
    # Add our declarative devices (excluding current machine)
    if [[ "${machineName}" != "monaco" && -n "$MONACO_ID" ]]; then
      echo "Adding Monaco device: $MONACO_ID"
      call_api POST "/rest/config/devices" \
        "{\"deviceID\":\"$MONACO_ID\",\"name\":\"Monaco\",\"addresses\":[\"dynamic\"],\"compression\":\"metadata\",\"autoAcceptFolders\":false}" >/dev/null
    fi
    
    if [[ "${machineName}" != "silver" && -n "$SILVER_ID" ]]; then
      echo "Adding Silver device: $SILVER_ID"
      call_api POST "/rest/config/devices" \
        "{\"deviceID\":\"$SILVER_ID\",\"name\":\"Silver\",\"addresses\":[\"dynamic\"],\"compression\":\"metadata\",\"autoAcceptFolders\":false}" >/dev/null
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
      
      call_api POST "/rest/config/folders" \
        "{\"id\":\"nix-sync-test\",\"path\":\"${config.home.homeDirectory}/nix-syncthing\",\"devices\":$FOLDER_DEVICES,\"type\":\"sendreceive\",\"fsWatcherEnabled\":true,\"fsWatcherDelayS\":10,\"rescanIntervalS\":180,\"ignorePerms\":true}" >/dev/null
    fi
    
    # Restart Syncthing to apply configuration
    echo "Configuration complete, restarting Syncthing to apply changes..."
    call_api POST "/rest/system/restart" "" >/dev/null
    
    echo "Syncthing configuration successfully updated and applied"
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
    if [[ -n "''${DRY_RUN_CMD:-}" ]]; then
      echo "[DRY-RUN] Would update Syncthing configuration from shared secret"
      if [[ -f "${sharedSecretPath}" ]]; then
        MONACO_ID=$(${pkgs.jq}/bin/jq -r '.devices.monaco // empty' "${sharedSecretPath}" 2>/dev/null || echo "")
        SILVER_ID=$(${pkgs.jq}/bin/jq -r '.devices.silver // empty' "${sharedSecretPath}" 2>/dev/null || echo "")
        echo "[DRY-RUN] Would wait for Syncthing API and config.xml"
        echo "[DRY-RUN] Would remove all existing devices and folders"
        if [[ "${machineName}" != "monaco" && -n "$MONACO_ID" ]]; then
          echo "[DRY-RUN] Would add Monaco device: $MONACO_ID"
        fi
        if [[ "${machineName}" != "silver" && -n "$SILVER_ID" ]]; then
          echo "[DRY-RUN] Would add Silver device: $SILVER_ID"
        fi
        if [[ -n "$MONACO_ID" && -n "$SILVER_ID" ]]; then
          echo "[DRY-RUN] Would add test folder 'nix-sync-test' shared between devices"
        fi
        echo "[DRY-RUN] Would restart Syncthing to apply configuration"
      else
        echo "[DRY-RUN] Shared secret not found - would run with certificate-based identity only"
      fi
    else
      # Run in background to avoid blocking activation
      (${updateSyncthingConfigScript} &) || true
    fi
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

  # Create helper scripts for manual operations (useful for debugging)
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
    (pkgs.writeShellScriptBin "syncthing-update-config" ''
      echo "Manually updating Syncthing configuration for ${machineName}..."
      ${updateSyncthingConfigScript}
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
