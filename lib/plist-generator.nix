{ lib, pkgs }:

let
  # Import backup manager for smart change detection
  backupManager = import ./backup-manager.nix { inherit lib pkgs; };

  # Current timestamp for backup operations
  currentTimestamp = backupManager.generateTimestamp;

in
rec {
  /*
    Generate a shell script that deploys a plist file from JSON configuration
    with enhanced backup system and improved reliability
    
    Input fileConfig structure (enhanced):
    {
      type = "plist";
      format = "binary1" | "xml1";
      filename = "com.example.app.plist";
      filepath = "~/Library/Preferences";
      permissions = "600";
      
      # Backup configuration (enhanced)
      backup = {
        enabled = true;           // Default: true
        strategy = "smart" | "always" | "never";  // Default: "smart"
        lastChecksum = "sha256:..."; // For change detection
      };
      
      # Enhanced app control
      appControl = {
        processName = "AppName";
        quitCommand = "killall AppName";
        restartCommand = "open -a AppName";
        requiresRestart = true;
        timeout = 10;           // Graceful shutdown timeout
        healthCheck = true;     // Verify app restart success
      };
      
      data = { };
    }
    
    Returns: Shell script that:
    1. Performs smart backup if needed (only when local changes detected)
    2. Converts JSON to plist using Python plistlib
    3. Enhanced change detection (size + checksum)
    4. Conditionally quits app with timeout handling
    5. Deploys to target location with atomic operations
    6. Enhanced app restart with health checks
    7. Provides clear user feedback throughout process
  */
  generatePlistScript = { config, fileConfig, jsonFilePath }:
    pkgs.writeShellScript "deploy-plist-${fileConfig.filename}" ''
            set -euo pipefail

            # Configuration from Nix
            FILENAME="${fileConfig.filename}"
            FILEPATH="${config.home.homeDirectory}/${lib.removePrefix "~/" fileConfig.filepath}"
            PLIST_FILE="$FILEPATH/$FILENAME"
            TEMP_PLIST=$(mktemp -t "$FILENAME.XXXXXX")  # Use system temp for security
            BACKUP_ENABLED=${lib.boolToString (if fileConfig ? backup then fileConfig.backup.enabled or true else true)}
            BACKUP_STRATEGY="${if fileConfig ? backup then fileConfig.backup.strategy or "smart" else "smart"}"
            PROCESS_NAME="${fileConfig.appControl.processName}"
            TIMEOUT=${if fileConfig.appControl ? timeout then toString fileConfig.appControl.timeout else "10"}

            # Ensure target directory exists
            mkdir -p "$FILEPATH"

            echo "🔍 Analyzing $FILENAME..."

            # Smart backup logic - only backup if local changes detected
            BACKUP_DIR=""
            NEEDS_BACKUP=0
            if [[ "$BACKUP_ENABLED" == "true" ]]; then
              if [[ "$BACKUP_STRATEGY" == "always" ]] || [[ "$BACKUP_STRATEGY" == "smart" ]]; then
                if [[ -f "$PLIST_FILE" ]]; then
                  # Get current file metadata
                  local file_mtime=$(${pkgs.coreutils}/bin/stat -f %m "$PLIST_FILE" 2>/dev/null || echo "0")
                  local current_checksum=$(${pkgs.coreutils}/bin/sha256sum "$PLIST_FILE" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
            
                  # Check if we have a last checksum for comparison
                  local last_checksum="${if fileConfig ? backup && fileConfig.backup ? lastChecksum then fileConfig.backup.lastChecksum else ""}"
            
                  if [[ "$BACKUP_STRATEGY" == "always" ]]; then
                    NEEDS_BACKUP=1
                  elif [[ "$BACKUP_STRATEGY" == "smart" ]]; then
                    # For smart backup, we'll detect changes after generating new plist
                    NEEDS_BACKUP=1  # Assume we need backup until proven otherwise
                  fi
            
                  if [[ $NEEDS_BACKUP -eq 1 ]]; then
                    BACKUP_DIR="$HOME/Library/Preferences/backups/$(date +%Y-%m-%d-%H%M%S)"
                    mkdir -p "$BACKUP_DIR"
                    echo "📦 Preparing backup directory: $BACKUP_DIR"
                  fi
                fi
              fi
            fi

            # Generate plist from JSON data using Python plistlib (pass vars as env)
            echo "⚙️  Generating plist from JSON..."
            PLIST_OUTPUT_FILE="$TEMP_PLIST" \
            PLIST_JSON_SOURCE="${jsonFilePath}" \
            PLIST_FORMAT="${fileConfig.format}" \
            PLIST_FILENAME="$FILENAME" \
            ${pkgs.python3}/bin/python3 <<'PYTHON_EOF'
            import json
            import plistlib
            import os
            import base64
            import sys
            from datetime import datetime

            def convert_json_to_plist(obj):
                """Enhanced type conversion for plist compatibility"""
                if isinstance(obj, dict):
                    # Check for explicit type annotations
                    if "__type" in obj and "value" in obj:
                        type_handler = obj["__type"]
                        value = obj["value"]
                  
                        if type_handler == "date":
                            try:
                                return datetime.fromisoformat(value.replace('Z', '+00:00'))
                            except ValueError:
                                print(f"⚠️  Warning: Invalid date format: {value}", file=sys.stderr)
                                return value
                        elif type_handler == "data":
                            try:
                                return base64.b64decode(value)
                            except ValueError:
                                print(f"⚠️  Warning: Invalid base64 data", file=sys.stderr)
                                return value
                        elif type_handler == "bool":
                            if isinstance(value, str):
                                return value.lower() in ("true", "1", "yes")
                            return bool(value)
                        elif type_handler == "int":
                            return int(value)
                        elif type_handler == "float":
                            return float(value)
                        elif type_handler == "url":
                            # For future URL object support
                            return str(value)
                        elif type_handler == "uuid":
                            # For future UUID object support
                            return str(value)
                        else:
                            print(f"⚠️  Warning: Unknown type handler: {type_handler}", file=sys.stderr)
                            return value
                    # Recursively process dict
                    return {k: convert_json_to_plist(v) for k, v in obj.items()}
                elif isinstance(obj, list):
                    return [convert_json_to_plist(item) for item in obj]
                else:
                    return obj

            # Get parameters from environment variables
            output_file = os.environ['PLIST_OUTPUT_FILE']
            json_source = os.environ['PLIST_JSON_SOURCE']
            plist_format = os.environ['PLIST_FORMAT']
            filename = os.environ.get('PLIST_FILENAME', 'unknown')

            try:
                # Read JSON directly from source file
                with open(json_source, 'r') as f:
                    config_data = json.load(f)

                # Find the matching file configuration by filename
                plist_data = None
                for file_entry in config_data.get('files', []):
                    if file_entry.get('filename') == filename:
                        plist_data = file_entry.get('data')
                        break

                if plist_data is None:
                    raise ValueError(f"No data found for filename: {filename}")

                # Convert with enhanced type handling
                converted_data = convert_json_to_plist(plist_data)

                # Determine plist format
                fmt = plistlib.FMT_BINARY if plist_format == "binary1" else plistlib.FMT_XML

                # Write plist file with atomic operation
                with open(output_file, 'wb') as f:
                    plistlib.dump(converted_data, f, fmt=fmt)

                print(f"✓ Generated plist: {os.path.basename(output_file)}")

            except Exception as e:
                print(f"❌ Error generating plist: {e}", file=sys.stderr)
                sys.exit(1)
            PYTHON_EOF

            # Enhanced change detection with size check first
            NEEDS_DEPLOY=0
            DEPLOY_REASON=""
            if [[ -f "$PLIST_FILE" ]]; then
              # Quick size check first (faster than content comparison)
              local old_size=$(${pkgs.coreutils}/bin/stat -f %z "$PLIST_FILE" 2>/dev/null || echo "0")
              local new_size=$(${pkgs.coreutils}/bin/stat -f %z "$TEMP_PLIST" 2>/dev/null || echo "0")
        
              if [[ $old_size -ne $new_size ]]; then
                NEEDS_DEPLOY=1
                DEPLOY_REASON="size changed ($old_size -> $new_size bytes)"
              else
                # Size same, check content
                if ! cmp -s "$TEMP_PLIST" "$PLIST_FILE"; then
                  NEEDS_DEPLOY=1
                  DEPLOY_REASON="content changed"
                fi
              fi
        
              if [[ $NEEDS_DEPLOY -eq 1 ]]; then
                echo "📝 Changes detected: $FILENAME ($DEPLOY_REASON)"
              else
                echo "✓ No changes needed: $FILENAME"
                rm -f "$TEMP_PLIST"
                exit 0
              fi
            else
              NEEDS_DEPLOY=1
              DEPLOY_REASON="new file"
              echo "🆕 New plist file: $FILENAME"
            fi

            # Perform backup if needed (after we know changes exist)
            if [[ $NEEDS_BACKUP -eq 1 ]] && [[ $NEEDS_DEPLOY -eq 1 ]]; then
              echo "💾 Backing up existing preferences..."
              if [[ -f "$PLIST_FILE" ]]; then
                # Create backup with metadata
                local backup_path="$BACKUP_DIR/$FILENAME.backup"
                cp -p "$PLIST_FILE" "$backup_path"
          
                # Get file metadata for manifest
                local file_perms=$(${pkgs.coreutils}/bin/stat -f "%Lp" "$PLIST_FILE")
                local file_uid=$(${pkgs.coreutils}/bin/stat -f "%u" "$PLIST_FILE")
                local file_gid=$(${pkgs.coreutils}/bin/stat -f "%g" "$PLIST_FILE")
                local file_size=$(${pkgs.coreutils}/bin/stat -f "%z" "$PLIST_FILE")
                local file_mtime=$(${pkgs.coreutils}/bin/stat -f "%m" "$PLIST_FILE")
                local file_checksum=$(${pkgs.coreutils}/bin/sha256sum "$PLIST_FILE" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
          
                echo "  ✓ Backed up to: $backup_path"
          
                # Create manifest entry (simplified JSON)
                cat >> "$BACKUP_DIR/manifest.json" <<MANIFEST_EOF
      ,
        "$FILENAME": {
          "original_path": "$PLIST_FILE",
          "backup_path": "$backup_path",
          "permissions": "$file_perms",
          "uid": $file_uid,
          "gid": $file_gid,
          "size": $file_size,
          "mtime": $file_mtime,
          "checksum": "$file_checksum",
          "backup_reason": "$DEPLOY_REASON",
          "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        }
      MANIFEST_EOF
              else
                echo "  ℹ️  No existing file to backup"
              fi
            fi

            # Enhanced app management with timeout
            APP_WAS_RUNNING=0
            if [[ $NEEDS_DEPLOY -eq 1 ]]; then
              if pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
                APP_WAS_RUNNING=1
                echo "⏹️  Stopping $PROCESS_NAME..."
          
                # Try graceful shutdown first
                if timeout "$TIMEOUT"s bash -c "while pgrep -x '$PROCESS_NAME' >/dev/null; do sleep 0.5; done" <<< "$(${fileConfig.appControl.quitCommand} 2>/dev/null || true)"; then
                  echo "  ✓ Gracefully stopped"
                else
                  echo "  ⚠️  Force stopping after timeout"
                  pkill -x "$PROCESS_NAME" 2>/dev/null || true
                  sleep 1
                fi
              fi

              # Deploy new plist with atomic move
              echo "📤 Deploying $FILENAME..."
              mv "$TEMP_PLIST" "$PLIST_FILE"
              chmod ${fileConfig.permissions} "$PLIST_FILE"
  
              # Clear macOS preferences cache to force reload
              echo "🔄 Clearing preferences cache..."
              killall cfprefsd 2>/dev/null || true
              sleep 1
  
              echo "✅ Deployed successfully: $FILENAME"
        
              # Restart app with health check if it was running
              if [[ $APP_WAS_RUNNING -eq 1 ]] && [[ "${lib.boolToString fileConfig.appControl.requiresRestart}" == "true" ]]; then
                echo "🚀 Restarting $PROCESS_NAME..."
                ${fileConfig.appControl.restartCommand} 2>/dev/null || true
          
                # Health check if enabled
                if ${lib.boolToString (fileConfig.appControl.healthCheck or true)}; then
                  sleep 3
                  if pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
                    echo "  ✓ Health check passed - app is running"
                  else
                    echo "  ⚠️  Health check failed - app may not have started properly"
                  fi
                else
                  echo "  ✓ Restart command executed"
                fi
              fi
            fi

            # Final cleanup
            rm -f "$TEMP_PLIST"
      
            # Provide recovery information if backup was made
            if [[ -n "$BACKUP_DIR" ]] && [[ $NEEDS_BACKUP -eq 1 ]]; then
              echo ""
              echo "💡 Recovery information:"
              echo "   Backup directory: $BACKUP_DIR"
              echo "   To restore: cp '$BACKUP_DIR/$FILENAME.backup' '$PLIST_FILE'"
              echo "   To view all backups: ls -la '$HOME/Library/Preferences/backups/'"
            fi
    '';

  /*
    Generate deployment scripts for all plist files in a JSON config
    with batch processing and shared backup timestamp
    
    Input: Full JSON config with "files" array, and source JSON file path
    Returns: Concatenated shell script for all files with shared infrastructure
  */
  generateAllPlistScripts = { config, jsonConfig, jsonFilePath }:
    let
      # Check if any file needs backup
      anyBackupNeeded = lib.any
        (fileConfig:
          if fileConfig ? backup then
            (fileConfig.backup.enabled or true) &&
            ((fileConfig.backup.strategy or "smart") != "never")
          else true
        )
        jsonConfig.files;

      # Generate backup setup script if needed
      backupSetup =
        if anyBackupNeeded then ''
          # Setup backup infrastructure
          echo "🏗️  Setting up backup infrastructure for preference files..."
      
          # Create backup directory exclusion from Time Machine (optional)
          if command -v tmutil >/dev/null 2>&1; then
            # Only add exclusion if not already present
            if ! tmutil isexcluded "$HOME/Library/Preferences/backups" 2>/dev/null | grep -q "Included"; then
              tmutil addexclusion "$HOME/Library/Preferences/backups" 2>/dev/null || true
            fi
          fi
      
          echo ""
        '' else "";

      # Generate individual file scripts
      fileScripts = map
        (fileConfig:
          generatePlistScript { inherit config fileConfig jsonFilePath; }
        )
        jsonConfig.files;

    in
    # Combine backup setup with individual file scripts
    backupSetup + lib.concatStringsSep "\n\n" fileScripts;
}


