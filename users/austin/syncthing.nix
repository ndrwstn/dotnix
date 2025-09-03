# users/austin/syncthing.nix - Simplified Syncthing configuration with direct config.xml generation
{ config, lib, pkgs, hostName ? "unknown", unstable, ... }:

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

  # Check if current machine is configured by checking if secrets exist
  isMachineConfigured = true; # Will be validated at runtime by checking secret files

  # Combined script that handles all syncthing setup with platform detection
  # IMPORTANT: This script now checks for changes BEFORE stopping syncthing to avoid
  # unnecessary service restarts. The flow is:
  # 1. Check if syncthing is running (but don't stop it)
  # 2. Extract secrets and generate config to temp file
  # 3. Compare temp config and certificates with existing ones
  # 4. Only stop syncthing if changes detected AND it's running
  # 5. Deploy changes and restart only when needed
  setupSyncthingScript = pkgs.writeShellScript "setup-syncthing" ''
    set -euo pipefail
    
    # Platform detection
    if [[ "${lib.boolToString pkgs.stdenv.isDarwin}" == "true" ]]; then
      PLATFORM="darwin"
      CONFIG_DIR="${config.home.homeDirectory}/Library/Application Support/Syncthing"
      SERVICE_NAME="org.nix-community.home.syncthing"
      LAUNCHCTL_CMD="/bin/launchctl"
      CMP_CMD="/usr/bin/cmp"
    else
      PLATFORM="linux"
      CONFIG_DIR="${config.home.homeDirectory}/.local/state/syncthing"
      SERVICE_NAME="syncthing.service"
      SYSTEMCTL_CMD="systemctl"
      CMP_CMD="cmp"
    fi
    
    CONFIG_FILE="$CONFIG_DIR/config.xml"
    
    echo "Setting up Syncthing for $PLATFORM platform"
    
    # Check if syncthing is currently running and remember state
    SYNCTHING_WAS_RUNNING=0
    if [[ "$PLATFORM" == "darwin" ]]; then
      if $LAUNCHCTL_CMD list | grep -q $SERVICE_NAME; then
        SYNCTHING_WAS_RUNNING=1
        echo "Syncthing is currently running"
      fi
    else
      if $SYSTEMCTL_CMD --user is-active $SERVICE_NAME >/dev/null 2>&1; then
        SYNCTHING_WAS_RUNNING=1
        echo "Syncthing is currently running"
      fi
    fi
    
    # === EXTRACT SECRETS ===
    echo "Extracting Syncthing secrets..."
    
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
    
    # === GENERATE CONFIG ===
    echo "Generating Syncthing config.xml..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Create temporary file for config generation
    CONFIG_TEMP=$(mktemp "$CONFIG_DIR/config.xml.XXXXXX")
    
    # Check if shared secret exists
    if [[ ! -f "${sharedSecretPath}" ]]; then
      echo "Warning: Shared syncthing secret not found at ${sharedSecretPath}"
      echo "Skipping device configuration - will use certificate-based identity only"
      exit 0
    fi
    
        # Read device IDs from secrets
        SHARED_CONFIG=$(cat "${sharedSecretPath}" 2>/dev/null || echo '{}')
        MACHINE_CONFIG=$(cat "${secretPath}" 2>/dev/null || echo '{}')

        # Extract own device ID
        OWN_DEVICE_ID=$(echo "$MACHINE_CONFIG" | ${pkgs.jq}/bin/jq -r '.deviceId // empty' 2>/dev/null || echo "")

        # Extract machine-specific GUI options from MACHINE_CONFIG with defaults
        GUI_ADDRESS=$(echo "$MACHINE_CONFIG" | ${pkgs.jq}/bin/jq -r '.machineOptions.guiAddress // "127.0.0.1:8384"')
        GUI_PORT=$(echo "$MACHINE_CONFIG" | ${pkgs.jq}/bin/jq -r '.machineOptions.guiPort // 8384')

        # Extract global options from SHARED_CONFIG with defaults
        # Note: For booleans, we use explicit null checks because jq's // operator treats false as falsy
        
        # Discovery options
        LISTEN_ADDRESS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.listenAddress // "default"')
        GLOBAL_ANNOUNCE_SERVER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.globalAnnounceServer // "default"')
        GLOBAL_ANNOUNCE_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.globalAnnounceEnabled as $val | if $val == null then true else $val end')
        LOCAL_ANNOUNCE_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.localAnnounceEnabled as $val | if $val == null then true else $val end')
        LOCAL_ANNOUNCE_PORT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.localAnnouncePort // 21027')
        LOCAL_ANNOUNCE_MC_ADDR=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.localAnnounceMCAddr // "[ff12::8384]:21027"')
        
        # Bandwidth options
        MAX_SEND_KBPS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.maxSendKbps // 0')
        MAX_RECV_KBPS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.maxRecvKbps // 0')
        LIMIT_BANDWIDTH_IN_LAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.limitBandwidthInLan as $val | if $val == null then false else $val end')
        
        # Relays and NAT options
        RELAYS_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.relaysEnabled as $val | if $val == null then false else $val end')
        NAT_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.natEnabled as $val | if $val == null then false else $val end')
        RELAY_RECONNECT_INTERVAL_M=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.relayReconnectIntervalM // 10')
        NAT_LEASE_MINUTES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.natLeaseMinutes // 60')
        NAT_RENEWAL_MINUTES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.natRenewalMinutes // 30')
        NAT_TIMEOUT_SECONDS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.natTimeoutSeconds // 10')
        
        # Usage reporting options
        UR_ACCEPTED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.urAccepted // -1')
        UR_SEEN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.urSeen // 3')
        UR_UNIQUE_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.urUniqueID // ""')
        UR_URL=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.urURL // "https://data.syncthing.net/newdata"')
        UR_POST_INSECURELY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.urPostInsecurely as $val | if $val == null then false else $val end')
        UR_INITIAL_DELAY_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.urInitialDelayS // 1800')
        
        # Update options
        AUTO_UPGRADE_INTERVAL_H=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.autoUpgradeIntervalH // 12')
        UPGRADE_TO_PRE_RELEASES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.upgradeToPreReleases as $val | if $val == null then false else $val end')
        RELEASES_URL=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.releasesURL // "https://upgrades.syncthing.net/meta.json"')
        
        # Performance options
        RECONNECTION_INTERVAL_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.reconnectionIntervalS // 60')
        KEEP_TEMPORARIES_H=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.keepTemporariesH // 24')
        CACHE_IGNORED_FILES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.cacheIgnoredFiles as $val | if $val == null then false else $val end')
        PROGRESS_UPDATE_INTERVAL_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.progressUpdateIntervalS // 5')
        TEMP_INDEX_MIN_BLOCKS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.tempIndexMinBlocks // 10')
        TRAFFIC_CLASS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.trafficClass // 0')
        SET_LOW_PRIORITY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.setLowPriority as $val | if $val == null then true else $val end')
        MAX_FOLDER_CONCURRENCY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.maxFolderConcurrency // 0')
        MAX_CONCURRENT_INCOMING_REQUEST_KIB=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.maxConcurrentIncomingRequestKiB // 0')
        
        # Connection priority options
        CONNECTION_PRIORITY_TCP_LAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionPriorityTcpLan // 10')
        CONNECTION_PRIORITY_QUIC_LAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionPriorityQuicLan // 20')
        CONNECTION_PRIORITY_TCP_WAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionPriorityTcpWan // 30')
        CONNECTION_PRIORITY_QUIC_WAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionPriorityQuicWan // 40')
        CONNECTION_PRIORITY_RELAY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionPriorityRelay // 50')
        CONNECTION_PRIORITY_UPGRADE_THRESHOLD=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionPriorityUpgradeThreshold // 0')
        CONNECTION_LIMIT_ENOUGH=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionLimitEnough // 0')
        CONNECTION_LIMIT_MAX=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.connectionLimitMax // 0')
        
        # Security options
        INSECURE_ALLOW_OLD_TLS_VERSIONS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.insecureAllowOldTLSVersions as $val | if $val == null then false else $val end')
        CRASH_REPORTING_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.crashReportingEnabled as $val | if $val == null then false else $val end')
        CRASH_REPORTING_URL=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.crashReportingURL // "https://crash.syncthing.net/newcrash"')
        
        # Other options
        START_BROWSER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.startBrowser as $val | if $val == null then false else $val end')
        OVERWRITE_REMOTE_DEVICE_NAMES_ON_CONNECT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.overwriteRemoteDeviceNamesOnConnect as $val | if $val == null then false else $val end')
        ANNOUNCE_LAN_ADDRESSES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.announceLANAddresses as $val | if $val == null then true else $val end')
        SEND_FULL_INDEX_ON_UPGRADE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.sendFullIndexOnUpgrade as $val | if $val == null then false else $val end')
        STUN_KEEPALIVE_START_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.stunKeepaliveStartS // 180')
        STUN_KEEPALIVE_MIN_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.stunKeepaliveMinS // 20')
        STUN_SERVER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.stunServer // "default"')
        DATABASE_TUNING=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.databaseTuning // "auto"')
        
        # Special case: minHomeDiskFree needs separate value and unit extraction
        MIN_HOME_DISK_FREE_VALUE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.minHomeDiskFree.value // 1')
        MIN_HOME_DISK_FREE_UNIT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.globalOptions.minHomeDiskFree.unit // "%"')
    
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

        # Generate complete config.xml to temporary file
        cat > "$CONFIG_TEMP" <<EOF
    <configuration version="37">
    EOF

        # Process folders from JSON configuration
        echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.folders // {} | to_entries[] | .key' | while IFS= read -r FOLDER_KEY; do
          if [[ -n "$FOLDER_KEY" ]]; then
            # Extract folder configuration with defaults
            FOLDER_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].id // $key')
            FOLDER_LABEL=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].label // $key')
            FOLDER_PATH_RAW=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" --arg home "${config.home.homeDirectory}" '.folders[$key].path // ($home + "/sync/" + $key)')
            
            # Expand ~ to home directory
            if [[ "$FOLDER_PATH_RAW" == "~"* ]]; then
              FOLDER_PATH="${config.home.homeDirectory}''${FOLDER_PATH_RAW:1}"
            else
              FOLDER_PATH="$FOLDER_PATH_RAW"
            fi
            
            # Core folder properties
            FOLDER_TYPE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].type // "sendreceive"')
            FILESYSTEM_TYPE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].filesystemType // "basic"')
            
            # Synchronization options
            RESCAN_INTERVAL_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].rescanIntervalS // 180')
            FS_WATCHER_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].fsWatcherEnabled as $val | if $val == null then true else $val end')
            FS_WATCHER_DELAY_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].fsWatcherDelayS // 10')
            FS_WATCHER_TIMEOUT_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].fsWatcherTimeoutS // 0')
            IGNORE_PERMS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].ignorePerms as $val | if $val == null then false else $val end')
            AUTO_NORMALIZE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].autoNormalize as $val | if $val == null then true else $val end')
            
            # Performance options
            COPIERS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].copiers // 0')
            PULLER_MAX_PENDING_KIB=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].pullerMaxPendingKiB // 0')
            HASHERS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].hashers // 0')
            ORDER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].order // "random"')
            SCAN_PROGRESS_INTERVAL_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].scanProgressIntervalS // 0')
            PULLER_PAUSE_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].pullerPauseS // 0')
            MAX_CONCURRENT_WRITES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].maxConcurrentWrites // 2')
            
            # Conflict & safety options
            MAX_CONFLICTS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].maxConflicts // 10')
            MIN_DISK_FREE_VALUE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].minDiskFree.value // 1')
            MIN_DISK_FREE_UNIT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].minDiskFree.unit // "%"')
            BLOCK_PULL_ORDER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].blockPullOrder // "standard"')
            COPY_RANGE_METHOD=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].copyRangeMethod // "standard"')
            
            # Advanced options
            DISABLE_SPARSE_FILES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].disableSparseFiles as $val | if $val == null then false else $val end')
            DISABLE_TEMP_INDEXES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].disableTempIndexes as $val | if $val == null then false else $val end')
            PAUSED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].paused as $val | if $val == null then false else $val end')
            WEAK_HASH_THRESHOLD_PCT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].weakHashThresholdPct // 25')
            MARKER_NAME=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].markerName // ".stfolder"')
            COPY_OWNERSHIP_FROM_PARENT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].copyOwnershipFromParent as $val | if $val == null then false else $val end')
            MOD_TIME_WINDOW_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].modTimeWindowS // 0')
            DISABLE_FSYNC=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].disableFsync as $val | if $val == null then false else $val end')
            CASE_SENSITIVE_FS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].caseSensitiveFS as $val | if $val == null then true else $val end')
            JUNCTIONS_AS_DIRS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].junctionsAsDirs as $val | if $val == null then false else $val end')
            SYNC_OWNERSHIP=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].syncOwnership as $val | if $val == null then false else $val end')
            SEND_OWNERSHIP=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].sendOwnership as $val | if $val == null then false else $val end')
            SYNC_XATTRS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].syncXattrs as $val | if $val == null then false else $val end')
            SEND_XATTRS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].sendXattrs as $val | if $val == null then false else $val end')
            
            # xattrFilter options
            XATTR_MAX_SINGLE_ENTRY_SIZE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].xattrFilter.maxSingleEntrySize // 1024')
            XATTR_MAX_TOTAL_SIZE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].xattrFilter.maxTotalSize // 4096')
            
            # Build device list for this folder
            FOLDER_DEVICES=""
            # Check if folder has specific device topology, otherwise use all devices
            FOLDER_DEVICE_LIST=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" --arg self "${machineName}" '
              if .folders[$key].devices then
                .folders[$key].devices[] | select(. != $self)
              else
                .devices | to_entries[] | select(.key != $self) | .key
              end
            ' 2>/dev/null || echo "")
            
            # Convert device names to device IDs and build XML
            while IFS= read -r DEVICE_NAME; do
              if [[ -n "$DEVICE_NAME" ]]; then
                DEVICE_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.devices[$device] // empty')
                if [[ -n "$DEVICE_ID" ]]; then
                  FOLDER_DEVICES="$FOLDER_DEVICES
                <device id=\"$DEVICE_ID\" introducedBy=\"\"></device>"
                fi
              fi
            done <<< "$FOLDER_DEVICE_LIST"
            
            # Handle versioning configuration
            VERSIONING_XML=""
            VERSIONING_TYPE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].versioning.type // empty')
            if [[ -n "$VERSIONING_TYPE" && "$VERSIONING_TYPE" != "null" ]]; then
              VERSIONING_XML="<versioning type=\"$VERSIONING_TYPE\">"
              # Add versioning parameters if they exist
              echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg key "$FOLDER_KEY" '.folders[$key].versioning.params // {} | to_entries[] | .key + ":" + (.value | tostring)' | while IFS=: read -r PARAM_KEY PARAM_VALUE; do
                if [[ -n "$PARAM_KEY" ]]; then
                  VERSIONING_XML="$VERSIONING_XML
                <param key=\"$PARAM_KEY\" val=\"$PARAM_VALUE\"></param>"
                fi
              done
              VERSIONING_XML="$VERSIONING_XML
            </versioning>"
            else
              VERSIONING_XML="<versioning></versioning>"
            fi
            
            # Generate folder XML
            cat >> "$CONFIG_TEMP" <<EOF
        <folder id="$FOLDER_ID" label="$FOLDER_LABEL" path="$FOLDER_PATH" type="$FOLDER_TYPE" rescanIntervalS="$RESCAN_INTERVAL_S" fsWatcherEnabled="$FS_WATCHER_ENABLED" fsWatcherDelayS="$FS_WATCHER_DELAY_S" fsWatcherTimeoutS="$FS_WATCHER_TIMEOUT_S" ignorePerms="$IGNORE_PERMS" autoNormalize="$AUTO_NORMALIZE">
            <filesystemType>$FILESYSTEM_TYPE</filesystemType>$FOLDER_DEVICES
            <minDiskFree unit="$MIN_DISK_FREE_UNIT">$MIN_DISK_FREE_VALUE</minDiskFree>
            $VERSIONING_XML
            <copiers>$COPIERS</copiers>
            <pullerMaxPendingKiB>$PULLER_MAX_PENDING_KIB</pullerMaxPendingKiB>
            <hashers>$HASHERS</hashers>
            <order>$ORDER</order>
            <ignoreDelete>false</ignoreDelete>
            <scanProgressIntervalS>$SCAN_PROGRESS_INTERVAL_S</scanProgressIntervalS>
            <pullerPauseS>$PULLER_PAUSE_S</pullerPauseS>
            <maxConflicts>$MAX_CONFLICTS</maxConflicts>
            <disableSparseFiles>$DISABLE_SPARSE_FILES</disableSparseFiles>
            <disableTempIndexes>$DISABLE_TEMP_INDEXES</disableTempIndexes>
            <paused>$PAUSED</paused>
            <weakHashThresholdPct>$WEAK_HASH_THRESHOLD_PCT</weakHashThresholdPct>
            <markerName>$MARKER_NAME</markerName>
            <copyOwnershipFromParent>$COPY_OWNERSHIP_FROM_PARENT</copyOwnershipFromParent>
            <modTimeWindowS>$MOD_TIME_WINDOW_S</modTimeWindowS>
            <maxConcurrentWrites>$MAX_CONCURRENT_WRITES</maxConcurrentWrites>
            <disableFsync>$DISABLE_FSYNC</disableFsync>
            <blockPullOrder>$BLOCK_PULL_ORDER</blockPullOrder>
            <copyRangeMethod>$COPY_RANGE_METHOD</copyRangeMethod>
            <caseSensitiveFS>$CASE_SENSITIVE_FS</caseSensitiveFS>
            <junctionsAsDirs>$JUNCTIONS_AS_DIRS</junctionsAsDirs>
            <syncOwnership>$SYNC_OWNERSHIP</syncOwnership>
            <sendOwnership>$SEND_OWNERSHIP</sendOwnership>
            <syncXattrs>$SYNC_XATTRS</syncXattrs>
            <sendXattrs>$SEND_XATTRS</sendXattrs>
            <xattrFilter>
                <maxSingleEntrySize>$XATTR_MAX_SINGLE_ENTRY_SIZE</maxSingleEntrySize>
                <maxTotalSize>$XATTR_MAX_TOTAL_SIZE</maxTotalSize>
            </xattrFilter>
        </folder>
    EOF
          fi
        done

        # Add devices dynamically (excluding current machine)
        echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg self "${machineName}" '
          .devices | to_entries[] | select(.key != $self) | .key + ":" + .value
        ' | while IFS=: read -r DEVICE_NAME DEVICE_ID; do
          if [[ -n "$DEVICE_ID" ]]; then
            # Capitalize first letter for display name
            DISPLAY_NAME="''${DEVICE_NAME^}"
        
            # Extract device options from SHARED_CONFIG with proper defaults
            # Core Device Options
            COMPRESSION=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].compression // "metadata"')
            INTRODUCER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].introducer as $val | if $val == null then false else $val end')
            SKIP_INTRODUCTION_REMOVALS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].skipIntroductionRemovals as $val | if $val == null then false else $val end')
            INTRODUCED_BY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].introducedBy // ""')
            PAUSED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].paused as $val | if $val == null then false else $val end')
            AUTO_ACCEPT_FOLDERS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].autoAcceptFolders as $val | if $val == null then false else $val end')
            UNTRUSTED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].untrusted as $val | if $val == null then false else $val end')
            
            # Network/Performance Options
            ADDRESSES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].addresses // ["dynamic"] | join(",")')
            MAX_SEND_KBPS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].maxSendKbps // 0')
            MAX_RECV_KBPS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].maxRecvKbps // 0')
            MAX_REQUEST_KIB=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].maxRequestKiB // 0')
            NUM_CONNECTIONS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].numConnections // 0')
            ALLOWED_NETWORKS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].allowedNetworks // [] | join(",")')
            
            # Advanced Options
            CERT_NAME=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].certName // "syncthing"')
            REMOTE_GUI_PORT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].remoteGUIPort // 0')
            IGNORED_FOLDERS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE_NAME" '.deviceOptions[$device].ignoredFolders // [] | join(",")')
            
            # Apply untrusted constraint validation
            if [[ "$UNTRUSTED" == "true" ]]; then
              INTRODUCER="false"
              AUTO_ACCEPT_FOLDERS="false"
            fi
        
            # Generate address elements
            ADDRESS_ELEMENTS=""
            IFS=',' read -ra ADDR_ARRAY <<< "$ADDRESSES"
            for addr in "''${ADDR_ARRAY[@]}"; do
              if [[ -n "$addr" ]]; then
                ADDRESS_ELEMENTS="$ADDRESS_ELEMENTS
            <address>$addr</address>"
              fi
            done
            
            # Generate allowedNetwork elements
            ALLOWED_NETWORK_ELEMENTS=""
            if [[ -n "$ALLOWED_NETWORKS" ]]; then
              IFS=',' read -ra NETWORK_ARRAY <<< "$ALLOWED_NETWORKS"
              for network in "''${NETWORK_ARRAY[@]}"; do
                if [[ -n "$network" ]]; then
                  ALLOWED_NETWORK_ELEMENTS="$ALLOWED_NETWORK_ELEMENTS
            <allowedNetwork>$network</allowedNetwork>"
                fi
              done
            fi
            
            # Generate ignoredFolder elements
            IGNORED_FOLDER_ELEMENTS=""
            if [[ -n "$IGNORED_FOLDERS" ]]; then
              IFS=',' read -ra FOLDER_ARRAY <<< "$IGNORED_FOLDERS"
              for folder in "''${FOLDER_ARRAY[@]}"; do
                if [[ -n "$folder" ]]; then
                  IGNORED_FOLDER_ELEMENTS="$IGNORED_FOLDER_ELEMENTS
            <ignoredFolder>$folder</ignoredFolder>"
                fi
              done
            fi
        
            cat >> "$CONFIG_TEMP" <<EOF
        <device id="$DEVICE_ID" name="$DISPLAY_NAME" compression="$COMPRESSION" introducer="$INTRODUCER" skipIntroductionRemovals="$SKIP_INTRODUCTION_REMOVALS" introducedBy="$INTRODUCED_BY">$ADDRESS_ELEMENTS
            <paused>$PAUSED</paused>
            <autoAcceptFolders>$AUTO_ACCEPT_FOLDERS</autoAcceptFolders>
            <maxSendKbps>$MAX_SEND_KBPS</maxSendKbps>
            <maxRecvKbps>$MAX_RECV_KBPS</maxRecvKbps>
            <maxRequestKiB>$MAX_REQUEST_KIB</maxRequestKiB>
            <untrusted>$UNTRUSTED</untrusted>
            <remoteGUIPort>$REMOTE_GUI_PORT</remoteGUIPort>
            <numConnections>$NUM_CONNECTIONS</numConnections>$ALLOWED_NETWORK_ELEMENTS$IGNORED_FOLDER_ELEMENTS
        </device>
    EOF
          fi
        done

        # Extract GUI credentials from secrets
        GUI_USER=$(cat "${extractDir}/gui-user" 2>/dev/null || echo "")
        GUI_PASSWORD_PLAIN=$(cat "${extractDir}/gui-password" 2>/dev/null || echo "")
    
        # Hash the password using bcrypt if it's not already hashed
        if [[ -n "$GUI_PASSWORD_PLAIN" ]]; then
          if [[ "$GUI_PASSWORD_PLAIN" =~ ^\$2[aby]\$ ]]; then
            # Password is already bcrypt hashed
            GUI_PASSWORD="$GUI_PASSWORD_PLAIN"
          else
            # Hash the plain password with bcrypt
            GUI_PASSWORD=$(echo "$GUI_PASSWORD_PLAIN" | ${pkgs.python3.withPackages (ps: [ ps.bcrypt ])}/bin/python3 -c '
    import bcrypt
    import sys
    password = sys.stdin.read().strip()
    if password:
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
        print(hashed.decode("utf-8"))
    else:
        print("")
    ')
          fi
        else
          GUI_PASSWORD=""
        fi
    
        # Add GUI and options configuration
        cat >> "$CONFIG_TEMP" <<EOF
        <gui enabled="true" tls="false" debugging="false">
            <address>$GUI_ADDRESS</address>
            <user>$GUI_USER</user>
            <password>$GUI_PASSWORD</password>
            <apikey>$API_KEY</apikey>
            <theme>default</theme>
        </gui>
        <ldap></ldap>
        <options>
            <listenAddress>$LISTEN_ADDRESS</listenAddress>
            <globalAnnounceServer>$GLOBAL_ANNOUNCE_SERVER</globalAnnounceServer>
            <globalAnnounceEnabled>$GLOBAL_ANNOUNCE_ENABLED</globalAnnounceEnabled>
            <localAnnounceEnabled>$LOCAL_ANNOUNCE_ENABLED</localAnnounceEnabled>
            <localAnnouncePort>$LOCAL_ANNOUNCE_PORT</localAnnouncePort>
            <localAnnounceMCAddr>$LOCAL_ANNOUNCE_MC_ADDR</localAnnounceMCAddr>
            <maxSendKbps>$MAX_SEND_KBPS</maxSendKbps>
            <maxRecvKbps>$MAX_RECV_KBPS</maxRecvKbps>
            <reconnectionIntervalS>$RECONNECTION_INTERVAL_S</reconnectionIntervalS>
            <relaysEnabled>$RELAYS_ENABLED</relaysEnabled>
            <relayReconnectIntervalM>$RELAY_RECONNECT_INTERVAL_M</relayReconnectIntervalM>
            <startBrowser>$START_BROWSER</startBrowser>
            <natEnabled>$NAT_ENABLED</natEnabled>
            <natLeaseMinutes>$NAT_LEASE_MINUTES</natLeaseMinutes>
            <natRenewalMinutes>$NAT_RENEWAL_MINUTES</natRenewalMinutes>
            <natTimeoutSeconds>$NAT_TIMEOUT_SECONDS</natTimeoutSeconds>
            <urAccepted>$UR_ACCEPTED</urAccepted>
            <urSeen>$UR_SEEN</urSeen>
            <urUniqueID>$UR_UNIQUE_ID</urUniqueID>
            <urURL>$UR_URL</urURL>
            <urPostInsecurely>$UR_POST_INSECURELY</urPostInsecurely>
            <urInitialDelayS>$UR_INITIAL_DELAY_S</urInitialDelayS>
            <autoUpgradeIntervalH>$AUTO_UPGRADE_INTERVAL_H</autoUpgradeIntervalH>
            <upgradeToPreReleases>$UPGRADE_TO_PRE_RELEASES</upgradeToPreReleases>
            <keepTemporariesH>$KEEP_TEMPORARIES_H</keepTemporariesH>
            <cacheIgnoredFiles>$CACHE_IGNORED_FILES</cacheIgnoredFiles>
            <progressUpdateIntervalS>$PROGRESS_UPDATE_INTERVAL_S</progressUpdateIntervalS>
            <limitBandwidthInLan>$LIMIT_BANDWIDTH_IN_LAN</limitBandwidthInLan>
            <minHomeDiskFree unit="$MIN_HOME_DISK_FREE_UNIT">$MIN_HOME_DISK_FREE_VALUE</minHomeDiskFree>
            <releasesURL>$RELEASES_URL</releasesURL>
            <overwriteRemoteDeviceNamesOnConnect>$OVERWRITE_REMOTE_DEVICE_NAMES_ON_CONNECT</overwriteRemoteDeviceNamesOnConnect>
            <tempIndexMinBlocks>$TEMP_INDEX_MIN_BLOCKS</tempIndexMinBlocks>
            <trafficClass>$TRAFFIC_CLASS</trafficClass>
            <setLowPriority>$SET_LOW_PRIORITY</setLowPriority>
            <maxFolderConcurrency>$MAX_FOLDER_CONCURRENCY</maxFolderConcurrency>
            <crashReportingURL>$CRASH_REPORTING_URL</crashReportingURL>
            <crashReportingEnabled>$CRASH_REPORTING_ENABLED</crashReportingEnabled>
            <stunKeepaliveStartS>$STUN_KEEPALIVE_START_S</stunKeepaliveStartS>
            <stunKeepaliveMinS>$STUN_KEEPALIVE_MIN_S</stunKeepaliveMinS>
            <stunServer>$STUN_SERVER</stunServer>
            <databaseTuning>$DATABASE_TUNING</databaseTuning>
            <maxConcurrentIncomingRequestKiB>$MAX_CONCURRENT_INCOMING_REQUEST_KIB</maxConcurrentIncomingRequestKiB>
            <announceLANAddresses>$ANNOUNCE_LAN_ADDRESSES</announceLANAddresses>
            <sendFullIndexOnUpgrade>$SEND_FULL_INDEX_ON_UPGRADE</sendFullIndexOnUpgrade>
            <connectionLimitEnough>$CONNECTION_LIMIT_ENOUGH</connectionLimitEnough>
            <connectionLimitMax>$CONNECTION_LIMIT_MAX</connectionLimitMax>
            <insecureAllowOldTLSVersions>$INSECURE_ALLOW_OLD_TLS_VERSIONS</insecureAllowOldTLSVersions>
            <connectionPriorityTcpLan>$CONNECTION_PRIORITY_TCP_LAN</connectionPriorityTcpLan>
            <connectionPriorityQuicLan>$CONNECTION_PRIORITY_QUIC_LAN</connectionPriorityQuicLan>
            <connectionPriorityTcpWan>$CONNECTION_PRIORITY_TCP_WAN</connectionPriorityTcpWan>
            <connectionPriorityQuicWan>$CONNECTION_PRIORITY_QUIC_WAN</connectionPriorityQuicWan>
            <connectionPriorityRelay>$CONNECTION_PRIORITY_RELAY</connectionPriorityRelay>
            <connectionPriorityUpgradeThreshold>$CONNECTION_PRIORITY_UPGRADE_THRESHOLD</connectionPriorityUpgradeThreshold>
        </options>
        <remoteIgnoredDevice></remoteIgnoredDevice>
        <pendingDevice></pendingDevice>
        <pendingFolder></pendingFolder>
    </configuration>
    EOF

    echo "Successfully generated temporary Syncthing config"
    
    # === CHECK FOR CHANGES ===
    echo "Checking for configuration changes..."
    
    # Initialize change detection flags
    NEEDS_RESTART=0
    CONFIG_CHANGED=0
    CERTS_CHANGED=0
    
    # Check if config.xml changed
    if [[ -f "$CONFIG_FILE" ]]; then
      if $CMP_CMD -s "$CONFIG_TEMP" "$CONFIG_FILE" 2>/dev/null; then
        echo "Config.xml is unchanged"
      else
        echo "Config.xml has changed"
        CONFIG_CHANGED=1
        NEEDS_RESTART=1
      fi
    else
      echo "Config.xml does not exist, will be created"
      CONFIG_CHANGED=1
      NEEDS_RESTART=1
    fi
    
    # Check if certificates need updating
    if [[ -f "$CONFIG_DIR/cert.pem" ]] && $CMP_CMD -s "${extractDir}/cert.pem" "$CONFIG_DIR/cert.pem"; then
      echo "Certificate is up-to-date"
    else
      echo "Certificate needs updating"
      CERTS_CHANGED=1
      NEEDS_RESTART=1
    fi
    
    if [[ -f "$CONFIG_DIR/key.pem" ]] && $CMP_CMD -s "${extractDir}/key.pem" "$CONFIG_DIR/key.pem"; then
      echo "Private key is up-to-date"
    else
      echo "Private key needs updating"
      CERTS_CHANGED=1
      NEEDS_RESTART=1
    fi
    
    # === CONDITIONAL SERVICE STOP ===
    # Only stop syncthing if it's running AND changes need to be deployed
    if [[ $SYNCTHING_WAS_RUNNING -eq 1 ]] && [[ $NEEDS_RESTART -eq 1 ]]; then
      echo "Stopping Syncthing service to deploy changes..."
      if [[ "$PLATFORM" == "darwin" ]]; then
        $LAUNCHCTL_CMD stop $SERVICE_NAME 2>/dev/null || true
      else
        $SYSTEMCTL_CMD --user stop $SERVICE_NAME 2>/dev/null || true
      fi
      sleep 2
    fi
    
    # === DEPLOY CHANGES ===
    # Deploy config if it changed
    if [[ $CONFIG_CHANGED -eq 1 ]]; then
      echo "Deploying new Syncthing config.xml..."
      mv "$CONFIG_TEMP" "$CONFIG_FILE"
      chmod 600 "$CONFIG_FILE"
      echo "Config deployed successfully"
      echo "API key: $API_KEY"
    else
      # Clean up temp file if no changes
      rm -f "$CONFIG_TEMP"
    fi
    
    # Deploy certificates if they changed
    if [[ $CERTS_CHANGED -eq 1 ]]; then
      echo "Deploying new Syncthing certificates..."
      
      # Deploy certificates (remove existing files first to avoid permission issues)
      rm -f "$CONFIG_DIR/cert.pem" "$CONFIG_DIR/key.pem"
      cp "${extractDir}/cert.pem" "$CONFIG_DIR/cert.pem"
      cp "${extractDir}/key.pem" "$CONFIG_DIR/key.pem"
      chmod 400 "$CONFIG_DIR/cert.pem"
      chmod 400 "$CONFIG_DIR/key.pem"
      
      echo "Certificates deployed successfully"
    fi
    
    # === CONDITIONAL SERVICE START ===
    # Only start syncthing if it was stopped for changes
    if [[ $SYNCTHING_WAS_RUNNING -eq 1 ]] && [[ $NEEDS_RESTART -eq 1 ]]; then
      echo "Starting Syncthing service after deploying changes..."
      if [[ "$PLATFORM" == "darwin" ]]; then
        $LAUNCHCTL_CMD start $SERVICE_NAME 2>/dev/null || true
      else
        $SYSTEMCTL_CMD --user start $SERVICE_NAME 2>/dev/null || true
      fi
      echo "Syncthing restarted successfully"
    elif [[ $SYNCTHING_WAS_RUNNING -eq 1 ]]; then
      echo "No changes detected, Syncthing continues running without restart"
    elif [[ $NEEDS_RESTART -eq 1 ]]; then
      echo "Changes deployed. Syncthing was not running, changes will be used on next start"
    else
      echo "No changes detected and Syncthing was not running"
    fi
    
    echo "Syncthing setup completed successfully"
  '';





in
{
  # Only configure Syncthing if machine is in the configured list
  # Combined setup script that handles secrets, config generation, and certificate deployment
  home.activation.setupSyncthing = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupSyncthingScript}
  '');

  # Configure Syncthing service
  # Note: devices, folders, GUI settings, and options are managed via generated config.xml
  # This approach provides more reliable configuration than using NixOS service settings
  services.syncthing = lib.mkIf isMachineConfigured {
    enable = true;
    package = pkgs.syncthing;
  };

  # Warning messages
  warnings = lib.optional (!isMachineConfigured)
    "Syncthing is disabled for machine '${machineName}' - machine-specific secret file not found";
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
