# users/austin/syncthing.nix - Simplified Syncthing configuration with direct config.xml generation
{ config, lib, pkgs, hostName ? "unknown", ... }:

let
  # Use the hostName parameter passed from flake, normalize to lowercase
  machineName = lib.toLower hostName;

  # Path to the JSON secret files (provided by agenix)
  secretPath = "/run/agenix/syncthing-${machineName}";
  sharedSecretPath = "/run/agenix/syncthing";

  # Directory for extracted secrets
  extractDir = "${config.home.homeDirectory}/.config/syncthing-secrets";

  # Note: Configuration is generated directly as config.xml at service start
  # This replaces the complex REST API approach with a simpler, more reliable method
  # Secrets are read at runtime when agenix has decrypted them

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

  # Script to generate complete Syncthing config.xml at service start
  generateSyncthingConfigScript = pkgs.writeShellScript "generate-syncthing-config" ''
    set -euo pipefail
    
    # Determine config directory based on platform
    if [[ "${toString pkgs.stdenv.isLinux}" == "true" ]]; then
      CONFIG_DIR="${config.home.homeDirectory}/.local/state/syncthing"
    else
      CONFIG_DIR="${config.home.homeDirectory}/Library/Application Support/Syncthing"
    fi
    CONFIG_FILE="$CONFIG_DIR/config.xml"
    
    echo "Generating Syncthing config.xml at $CONFIG_FILE"
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Check if shared secret exists
    if [[ ! -f "${sharedSecretPath}" ]]; then
      echo "Warning: Shared syncthing secret not found at ${sharedSecretPath}"
      echo "Skipping device configuration - will use certificate-based identity only"
      exit 0
    fi
    
    # Check if machine-specific secret exists
    if [[ ! -f "${secretPath}" ]]; then
      echo "Warning: Machine syncthing secret not found at ${secretPath}"
      echo "Skipping configuration generation"
      exit 0
    fi
    
    # Read device IDs from secrets
    SHARED_CONFIG=$(cat "${sharedSecretPath}" 2>/dev/null || echo '{}')
    MACHINE_CONFIG=$(cat "${secretPath}" 2>/dev/null || echo '{}')
    
    # Extract own device ID
    OWN_DEVICE_ID=$(echo "$MACHINE_CONFIG" | ${pkgs.jq}/bin/jq -r '.deviceId // empty' 2>/dev/null || echo "")
    
    # Count available devices for logging
    DEVICE_COUNT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg self "${machineName}" '
      .devices | to_entries[] | select(.key != $self) | .key
    ' 2>/dev/null | wc -l || echo "0")
    
    # Preserve existing API key if config exists
    EXISTING_API_KEY=""
    if [[ -f "$CONFIG_FILE" ]]; then
      EXISTING_API_KEY=$(${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' "$CONFIG_FILE" 2>/dev/null || echo "")
    fi
    
    # Generate new API key if none exists
    if [[ -z "$EXISTING_API_KEY" ]]; then
      API_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 16)
    else
      API_KEY="$EXISTING_API_KEY"
    fi
    
    echo "Generating config for machine: ${machineName}"
    echo "Own device ID: $OWN_DEVICE_ID"
    echo "Available peer devices: $DEVICE_COUNT"
    
    # Get all device IDs except our own for folder configuration
    FOLDER_DEVICE_IDS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg self "${machineName}" '
      .devices | to_entries[] | select(.key != $self) | .value
    ' 2>/dev/null || echo "")

    # Build XML device entries for folder
    FOLDER_DEVICES=""
    while IFS= read -r DEVICE_ID; do
      if [[ -n "$DEVICE_ID" ]]; then
        FOLDER_DEVICES="$FOLDER_DEVICES
            <device id=\"$DEVICE_ID\" introducedBy=\"\"></device>"
      fi
    done <<< "$FOLDER_DEVICE_IDS"

    # Generate complete config.xml
    cat > "$CONFIG_FILE" << EOF
    <configuration version="37">
        <folder id="nix-sync-test" label="Nix Sync Test" path="${config.home.homeDirectory}/nix-syncthing" type="sendreceive" rescanIntervalS="180" fsWatcherEnabled="true" fsWatcherDelayS="10" ignorePerms="true" autoNormalize="true">
            <filesystemType>basic</filesystemType>$FOLDER_DEVICES
            <minDiskFree unit="%">1</minDiskFree>
            <versioning></versioning>
            <copiers>0</copiers>
            <pullerMaxPendingKiB>0</pullerMaxPendingKiB>
            <hashers>0</hashers>
            <order>random</order>
            <ignoreDelete>false</ignoreDelete>
            <scanProgressIntervalS>0</scanProgressIntervalS>
            <pullerPauseS>0</pullerPauseS>
            <maxConflicts>10</maxConflicts>
            <disableSparseFiles>false</disableSparseFiles>
            <disableTempIndexes>false</disableTempIndexes>
            <paused>false</paused>
            <weakHashThresholdPct>25</weakHashThresholdPct>
            <markerName>.stfolder</markerName>
            <copyOwnershipFromParent>false</copyOwnershipFromParent>
            <modTimeWindowS>0</modTimeWindowS>
            <maxConcurrentWrites>2</maxConcurrentWrites>
            <disableFsync>false</disableFsync>
            <blockPullOrder>standard</blockPullOrder>
            <copyRangeMethod>standard</copyRangeMethod>
            <caseSensitiveFS>true</caseSensitiveFS>
            <junctionsAsDirs>false</junctionsAsDirs>
            <syncOwnership>false</syncOwnership>
            <sendOwnership>false</sendOwnership>
            <syncXattrs>false</syncXattrs>
            <sendXattrs>false</sendXattrs>
            <xattrFilter>
                <maxSingleEntrySize>1024</maxSingleEntrySize>
                <maxTotalSize>4096</maxTotalSize>
            </xattrFilter>
        </folder>
    EOF

        # Add devices dynamically (excluding current machine)
        echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg self "${machineName}" '
          .devices | to_entries[] | select(.key != $self) | .key + ":" + .value
        ' | while IFS=: read -r DEVICE_NAME DEVICE_ID; do
          if [[ -n "$DEVICE_ID" ]]; then
            # Capitalize first letter for display name
            DISPLAY_NAME="''${DEVICE_NAME^}"
            
            cat >> "$CONFIG_FILE" << EOF
        <device id="$DEVICE_ID" name="$DISPLAY_NAME" compression="metadata" introducer="false" skipIntroductionRemovals="false" introducedBy="">
            <address>dynamic</address>
            <paused>false</paused>
            <autoAcceptFolders>false</autoAcceptFolders>
            <maxSendKbps>0</maxSendKbps>
            <maxRecvKbps>0</maxRecvKbps>
            <maxRequestKiB>0</maxRequestKiB>
            <untrusted>false</untrusted>
            <remoteGUIPort>0</remoteGUIPort>
            <numConnections>0</numConnections>
        </device>
    EOF
          fi
        done

        # Add GUI and options configuration
        cat >> "$CONFIG_FILE" << EOF
        <gui enabled="true" tls="false" debugging="false">
            <address>127.0.0.1:${toString currentConfig.guiPort}</address>
            <apikey>$API_KEY</apikey>
            <theme>default</theme>
        </gui>
        <ldap></ldap>
        <options>
            <listenAddress>default</listenAddress>
            <globalAnnounceServer>default</globalAnnounceServer>
            <globalAnnounceEnabled>false</globalAnnounceEnabled>
            <localAnnounceEnabled>true</localAnnounceEnabled>
            <localAnnouncePort>21027</localAnnouncePort>
            <localAnnounceMCAddr>[ff12::8384]:21027</localAnnounceMCAddr>
            <maxSendKbps>0</maxSendKbps>
            <maxRecvKbps>0</maxRecvKbps>
            <reconnectionIntervalS>60</reconnectionIntervalS>
            <relaysEnabled>false</relaysEnabled>
            <relayReconnectIntervalM>10</relayReconnectIntervalM>
            <startBrowser>false</startBrowser>
            <natEnabled>false</natEnabled>
            <natLeaseMinutes>60</natLeaseMinutes>
            <natRenewalMinutes>30</natRenewalMinutes>
            <natTimeoutSeconds>10</natTimeoutSeconds>
            <urAccepted>-1</urAccepted>
            <urSeen>3</urSeen>
            <urUniqueID></urUniqueID>
            <urURL>https://data.syncthing.net/newdata</urURL>
            <urPostInsecurely>false</urPostInsecurely>
            <urInitialDelayS>1800</urInitialDelayS>
            <autoUpgradeIntervalH>12</autoUpgradeIntervalH>
            <upgradeToPreReleases>false</upgradeToPreReleases>
            <keepTemporariesH>24</keepTemporariesH>
            <cacheIgnoredFiles>false</cacheIgnoredFiles>
            <progressUpdateIntervalS>5</progressUpdateIntervalS>
            <limitBandwidthInLan>false</limitBandwidthInLan>
            <minHomeDiskFree unit="%">1</minHomeDiskFree>
            <releasesURL>https://upgrades.syncthing.net/meta.json</releasesURL>
            <overwriteRemoteDeviceNamesOnConnect>false</overwriteRemoteDeviceNamesOnConnect>
            <tempIndexMinBlocks>10</tempIndexMinBlocks>
            <trafficClass>0</trafficClass>
            <setLowPriority>true</setLowPriority>
            <maxFolderConcurrency>0</maxFolderConcurrency>
            <crashReportingURL>https://crash.syncthing.net/newcrash</crashReportingURL>
            <crashReportingEnabled>false</crashReportingEnabled>
            <stunKeepaliveStartS>180</stunKeepaliveStartS>
            <stunKeepaliveMinS>20</stunKeepaliveMinS>
            <stunServer>default</stunServer>
            <databaseTuning>auto</databaseTuning>
            <maxConcurrentIncomingRequestKiB>0</maxConcurrentIncomingRequestKiB>
            <announceLANAddresses>true</announceLANAddresses>
            <sendFullIndexOnUpgrade>false</sendFullIndexOnUpgrade>
            <connectionLimitEnough>0</connectionLimitEnough>
            <connectionLimitMax>0</connectionLimitMax>
            <insecureAllowOldTLSVersions>false</insecureAllowOldTLSVersions>
            <connectionPriorityTcpLan>10</connectionPriorityTcpLan>
            <connectionPriorityQuicLan>20</connectionPriorityQuicLan>
            <connectionPriorityTcpWan>30</connectionPriorityTcpWan>
            <connectionPriorityQuicWan>40</connectionPriorityQuicWan>
            <connectionPriorityRelay>50</connectionPriorityRelay>
            <connectionPriorityUpgradeThreshold>0</connectionPriorityUpgradeThreshold>
        </options>
        <remoteIgnoredDevice></remoteIgnoredDevice>
        <pendingDevice></pendingDevice>
        <pendingFolder></pendingFolder>
    </configuration>
    EOF

        echo "Successfully generated Syncthing config.xml"
        echo "Config file: $CONFIG_FILE"
        echo "API key: $API_KEY"
  '';

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

  # Generate syncthing configuration before service starts
  home.activation.generateSyncthingConfig = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "extractSyncthingSecrets" ] ''
    $DRY_RUN_CMD ${generateSyncthingConfigScript}
  '');

  # Configure Syncthing service (devices/folders managed via generated config.xml)
  services.syncthing = lib.mkIf isMachineConfigured {
    enable = true;
    guiAddress = "127.0.0.1:${toString currentConfig.guiPort}";
    passwordFile = "${extractDir}/gui-password";

    # Don't override devices/folders - managed via generated config.xml
    overrideDevices = false;
    overrideFolders = false;

    settings = {
      options = syncthingGlobalOptions;
    };
  };

  # Create a systemd user service override for NixOS to handle GUI authentication
  systemd.user.services.syncthing = lib.mkIf (isMachineConfigured && pkgs.stdenv.isLinux) {
    Service = {
      # Ensure secrets are available and config is generated before starting
      ExecStartPre = [
        "${extractSecretsScript}"
        "${generateSyncthingConfigScript}"
      ];
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
    (pkgs.writeShellScriptBin "syncthing-generate-config" ''
      echo "Manually generating Syncthing configuration for ${machineName}..."
      ${generateSyncthingConfigScript}
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
    lib.hm.dag.entryAfter [ "generateSyncthingConfig" ] ''
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
    lib.hm.dag.entryAfter [ "generateSyncthingConfig" ] ''
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
        
        if [[ -f "$SYNCTHING_DIR/key.pem" ]] && ! ${pkgs.diffutils}/bin/cmp -s "${extractDir}/key.pem" "$SYNCTHING_DIR/key.pem"; then
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
