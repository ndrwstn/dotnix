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

  # Check if current machine is configured by checking if secrets exist
  isMachineConfigured = true; # Will be validated at runtime by checking secret files

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



  # Script to generate complete Syncthing config.xml at service start
  generateSyncthingConfigScript = pkgs.writeShellScript "generate-syncthing-config" ''
        set -euo pipefail
    
        # Determine config directory based on platform
        if [[ "${lib.boolToString pkgs.stdenv.isLinux}" == "true" ]]; then
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

        # Extract machine-specific GUI options from MACHINE_CONFIG with defaults
        GUI_ADDRESS=$(echo "$MACHINE_CONFIG" | ${pkgs.jq}/bin/jq -r '.machineOptions.guiAddress // "127.0.0.1:8384"')
        GUI_PORT=$(echo "$MACHINE_CONFIG" | ${pkgs.jq}/bin/jq -r '.machineOptions.guiPort // 8384')

        # Extract global options from SHARED_CONFIG with defaults
        # Note: For booleans, we use explicit null checks because jq's // operator treats false as falsy
        
        # Discovery options
        LISTEN_ADDRESS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.listenAddress // "default"')
        GLOBAL_ANNOUNCE_SERVER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.globalAnnounceServer // "default"')
        GLOBAL_ANNOUNCE_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.globalAnnounceEnabled as $val | if $val == null then true else $val end')
        LOCAL_ANNOUNCE_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.localAnnounceEnabled as $val | if $val == null then true else $val end')
        LOCAL_ANNOUNCE_PORT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.localAnnouncePort // 21027')
        LOCAL_ANNOUNCE_MC_ADDR=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.localAnnounceMCAddr // "[ff12::8384]:21027"')
        
        # Bandwidth options
        MAX_SEND_KBPS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.maxSendKbps // 0')
        MAX_RECV_KBPS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.maxRecvKbps // 0')
        LIMIT_BANDWIDTH_IN_LAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.limitBandwidthInLan as $val | if $val == null then false else $val end')
        
        # Relays and NAT options
        RELAYS_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.relaysEnabled as $val | if $val == null then false else $val end')
        NAT_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.natEnabled as $val | if $val == null then false else $val end')
        RELAY_RECONNECT_INTERVAL_M=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.relayReconnectIntervalM // 10')
        NAT_LEASE_MINUTES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.natLeaseMinutes // 60')
        NAT_RENEWAL_MINUTES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.natRenewalMinutes // 30')
        NAT_TIMEOUT_SECONDS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.natTimeoutSeconds // 10')
        
        # Usage reporting options
        UR_ACCEPTED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.urAccepted // -1')
        UR_SEEN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.urSeen // 3')
        UR_UNIQUE_ID=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.urUniqueID // ""')
        UR_URL=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.urURL // "https://data.syncthing.net/newdata"')
        UR_POST_INSECURELY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.urPostInsecurely as $val | if $val == null then false else $val end')
        UR_INITIAL_DELAY_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.urInitialDelayS // 1800')
        
        # Update options
        AUTO_UPGRADE_INTERVAL_H=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.autoUpgradeIntervalH // 12')
        UPGRADE_TO_PRE_RELEASES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.upgradeToPreReleases as $val | if $val == null then false else $val end')
        RELEASES_URL=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.releasesURL // "https://upgrades.syncthing.net/meta.json"')
        
        # Performance options
        RECONNECTION_INTERVAL_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.reconnectionIntervalS // 60')
        KEEP_TEMPORARIES_H=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.keepTemporariesH // 24')
        CACHE_IGNORED_FILES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.cacheIgnoredFiles as $val | if $val == null then false else $val end')
        PROGRESS_UPDATE_INTERVAL_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.progressUpdateIntervalS // 5')
        TEMP_INDEX_MIN_BLOCKS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.tempIndexMinBlocks // 10')
        TRAFFIC_CLASS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.trafficClass // 0')
        SET_LOW_PRIORITY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.setLowPriority as $val | if $val == null then true else $val end')
        MAX_FOLDER_CONCURRENCY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.maxFolderConcurrency // 0')
        MAX_CONCURRENT_INCOMING_REQUEST_KIB=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.maxConcurrentIncomingRequestKiB // 0')
        
        # Connection priority options
        CONNECTION_PRIORITY_TCP_LAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionPriorityTcpLan // 10')
        CONNECTION_PRIORITY_QUIC_LAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionPriorityQuicLan // 20')
        CONNECTION_PRIORITY_TCP_WAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionPriorityTcpWan // 30')
        CONNECTION_PRIORITY_QUIC_WAN=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionPriorityQuicWan // 40')
        CONNECTION_PRIORITY_RELAY=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionPriorityRelay // 50')
        CONNECTION_PRIORITY_UPGRADE_THRESHOLD=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionPriorityUpgradeThreshold // 0')
        CONNECTION_LIMIT_ENOUGH=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionLimitEnough // 0')
        CONNECTION_LIMIT_MAX=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.connectionLimitMax // 0')
        
        # Security options
        INSECURE_ALLOW_OLD_TLS_VERSIONS=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.insecureAllowOldTLSVersions as $val | if $val == null then false else $val end')
        CRASH_REPORTING_ENABLED=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.crashReportingEnabled as $val | if $val == null then false else $val end')
        CRASH_REPORTING_URL=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.crashReportingURL // "https://crash.syncthing.net/newcrash"')
        
        # Other options
        START_BROWSER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.startBrowser as $val | if $val == null then false else $val end')
        OVERWRITE_REMOTE_DEVICE_NAMES_ON_CONNECT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.overwriteRemoteDeviceNamesOnConnect as $val | if $val == null then false else $val end')
        ANNOUNCE_LAN_ADDRESSES=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.announceLANAddresses as $val | if $val == null then true else $val end')
        SEND_FULL_INDEX_ON_UPGRADE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.sendFullIndexOnUpgrade as $val | if $val == null then false else $val end')
        STUN_KEEPALIVE_START_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.stunKeepaliveStartS // 180')
        STUN_KEEPALIVE_MIN_S=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.stunKeepaliveMinS // 20')
        STUN_SERVER=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.stunServer // "default"')
        DATABASE_TUNING=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.databaseTuning // "auto"')
        
        # Special case: minHomeDiskFree needs separate value and unit extraction
        MIN_HOME_DISK_FREE_VALUE=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.minHomeDiskFree.value // 1')
        MIN_HOME_DISK_FREE_UNIT=$(echo "$SHARED_CONFIG" | ${pkgs.jq}/bin/jq -r '.options.minHomeDiskFree.unit // "%"')
    
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

        # Ensure clean config generation
        rm -f "$CONFIG_FILE"
    
        # Generate complete config.xml
        cat > "$CONFIG_FILE" <<EOF
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
        
            cat >> "$CONFIG_FILE" <<EOF
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
        cat >> "$CONFIG_FILE" <<EOF
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

        echo "Successfully generated Syncthing config.xml"
        echo "Config file: $CONFIG_FILE"
        echo "API key: $API_KEY"
  '';





in
{
  # Only configure Syncthing if machine is in the configured list
  # Extract secrets during home activation
  home.activation.extractSyncthingSecrets = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${extractSecretsScript}
  '');



  # Generate syncthing configuration before service starts
  home.activation.generateSyncthingConfig = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "extractSyncthingSecrets" ] ''
    ${generateSyncthingConfigScript}
  '');

  # Deploy certificates for Darwin
  home.activation.deploySyncthingCertificatesDarwin = lib.mkIf (isMachineConfigured && pkgs.stdenv.isDarwin) (
    lib.hm.dag.entryAfter [ "generateSyncthingConfig" ] ''
      ${pkgs.writeShellScript "deploy-syncthing-certificates-darwin" ''
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

  # Configure Syncthing service
  # Note: devices, folders, GUI settings, and options are managed via generated config.xml
  # This approach provides more reliable configuration than using NixOS service settings
  services.syncthing = lib.mkIf isMachineConfigured {
    enable = true;
    package = pkgs.syncthing;
  };

  # Smart certificate deployment for NixOS using activation scripts
  home.activation.deploySyncthingCertificatesLinux = lib.mkIf (isMachineConfigured && pkgs.stdenv.isLinux) (
    lib.hm.dag.entryAfter [ "generateSyncthingConfig" ] ''
      ${pkgs.writeShellScript "deploy-syncthing-certificates-linux" ''
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
    "Syncthing is disabled for machine '${machineName}' - machine-specific secret file not found";
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
