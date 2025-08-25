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

  # Machine-specific configuration
  devices = {
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

  # Check if current machine is configured
  isMachineConfigured = devices ? ${machineName};

  # Get configuration for current machine (only if configured)
  currentConfig = if isMachineConfigured then devices.${machineName} else null;

  # Fallback device IDs (will be replaced by actual IDs from shared secret at runtime)
  fallbackDeviceIds = {
    monaco = "DEVICE-ID-PLACEHOLDER-MONACO";
    silver = "DEVICE-ID-PLACEHOLDER-SILVER";
  };

  # Generate timestamp for test files
  timestamp = "$(date +%Y%m%d-%H%M%S)";

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

  # Script to create test files and .stignore
  createTestFilesScript = pkgs.writeShellScript "create-syncthing-test-files" ''
    set -euo pipefail
    
    # Create test directory
    TEST_DIR="${config.home.homeDirectory}/nix-syncthing"
    mkdir -p "$TEST_DIR"
    
    # Create test file with machine info
    TEST_FILE="$TEST_DIR/test-${machineName}-${timestamp}.txt"
    cat > "$TEST_FILE" << EOF
    # Syncthing Test File
    Machine: ${machineName}
    Hostname: $(hostname)
    User: $(whoami)
    Timestamp: $(date)
    UUID: $(${pkgs.util-linux}/bin/uuidgen 2>/dev/null || echo "N/A")
    
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

  # Configure Syncthing service with declarative configuration
  services.syncthing = lib.mkIf isMachineConfigured {
    enable = true;

    # GUI settings with machine-specific configuration
    guiAddress = currentConfig.guiAddress;

    # GUI authentication using passwordFile
    passwordFile = "${extractDir}/gui-password";

    # Declarative configuration - override existing devices and folders
    overrideDevices = true;
    overrideFolders = true;

    # Global Syncthing settings
    settings = {
      # Global options
      options = {
        urAccepted = -1; # Disable usage reporting
        relaysEnabled = false; # Local only
        localAnnounceEnabled = true;
        globalAnnounceEnabled = false;
        natEnabled = false;
      };

      # Device configuration (will be updated with actual IDs at runtime)
      devices = {
        monaco = {
          id = fallbackDeviceIds.monaco;
          compression = "metadata";
        };
        silver = {
          id = fallbackDeviceIds.silver;
          compression = "metadata";
        };
      };

      # Folder configuration
      folders = {
        "nix-sync-test" = {
          path = "${config.home.homeDirectory}/nix-syncthing";
          devices = [ "monaco" "silver" ];
          type = "sendreceive";
          fsWatcherEnabled = true;
          fsWatcherDelayS = 10;
          rescanIntervalS = 180; # 3 minutes for testing
          ignorePerms = true; # macOS/Linux compatibility
        };
      };
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

  # Warning message for unknown machines
  warnings = lib.optional (!isMachineConfigured)
    "Syncthing is disabled for machine '${machineName}' - not found in configured devices: ${lib.concatStringsSep ", " (lib.attrNames devices)}";
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
