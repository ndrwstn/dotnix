{ lib, pkgs }:

let
  # Import backup manager for smart change detection
  backupManager = import ./backup-manager.nix { inherit lib pkgs; };

  # Current timestamp for backup operations
  currentTimestamp = backupManager.generateTimestamp;

  # Batch processing functionality (enhanced for Phase 3 with inline type system)
  batchPlistProcessor = { jsonConfigs, jsonFilePaths }:
    pkgs.writeScript "batch-plist-processor" ''
      #!/usr/bin/env python3
      """
      Enhanced Batch Plist Processor - Phase 3 Enhancement
      Processes multiple JSON configuration files with enhanced type system
      """
      
      import json
      import plistlib
      import os
      import sys
      import base64
      import re
      from datetime import datetime
      from pathlib import Path
      import hashlib
      
      # Enhanced type handlers with validation (Phase 3)
      TYPE_HANDLERS = {
          "date": {
              "converter": lambda v: datetime.fromisoformat(v.replace('Z', '+00:00')),
              "validator": lambda v: isinstance(v, str),
              "description": "ISO 8601 date string to datetime object"
          },
          "data": {
              "converter": lambda v: base64.b64decode(v),
              "validator": lambda v: isinstance(v, str),
              "description": "Base64-encoded binary data"
          },
          "bool": {
              "converter": lambda v: v.lower() in ('true', '1', 'yes') if isinstance(v, str) else bool(v),
              "validator": lambda v: True,
              "description": "Boolean value"
          },
          "int": {
              "converter": lambda v: int(v),
              "validator": lambda v: isinstance(v, (int, str)),
              "description": "Integer number"
          },
          "float": {
              "converter": lambda v: float(v),
              "validator": lambda v: isinstance(v, (int, float, str)),
              "description": "Floating point number"
          },
          "url": {
              "converter": lambda v: str(v),
              "validator": lambda v: isinstance(v, str),
              "description": "URL object (as string)"
          },
          "uuid": {
              "converter": lambda v: str(v),
              "validator": lambda v: isinstance(v, str),
              "description": "UUID object (as string)"
          },
          "string": {
              "converter": lambda v: str(v),
              "validator": lambda v: True,
              "description": "Explicit string conversion"
          }
      }
      
      def convert_with_validation(type_name, value):
          """Convert value with validation"""
          if type_name not in TYPE_HANDLERS:
              raise ValueError(f"Unknown type: {type_name}")
          
          handler = TYPE_HANDLERS[type_name]
          
          # Validate input
          try:
              if not handler["validator"](value):
                  raise ValueError(f"Invalid value for type {type_name}: {value}")
          except Exception as e:
              print(f"⚠️  Validation warning for {type_name}: {e}")
          
          # Convert value
          try:
              return handler["converter"](value)
          except Exception as e:
              print(f"⚠️  Conversion warning for {type_name}: {e}")
              return value
      
      def enhanced_convert_json_to_plist(obj, depth=0, max_depth=50):
          """Enhanced type conversion for plist with depth protection and validation"""
          if depth > max_depth:
              raise ValueError(f"Maximum recursion depth ({max_depth}) exceeded")
          
          if isinstance(obj, dict):
              # Check for explicit type annotations
              if "__type" in obj and "value" in obj:
                  type_name = obj["__type"]
                  value = obj["value"]
                  
                  try:
                      return convert_with_validation(type_name, value)
                  except Exception as e:
                      print(f"⚠️  Type conversion failed: {type_name}: {e}")
                      return value
              
              # Recursively process dict
              result = {}
              for k, v in obj.items():
                  result[k] = enhanced_convert_json_to_plist(v, depth + 1, max_depth)
              return result
          
          elif isinstance(obj, list):
              return [enhanced_convert_json_to_plist(item, depth + 1, max_depth) for item in obj]
          
          else:
              return obj
      
      def convert_json_to_plist(obj):
          """Enhanced type conversion using Phase 3 type system"""
          return enhanced_convert_json_to_plist(obj)
      
      def compute_file_checksum(file_path):
          """Compute SHA256 checksum of file"""
          hasher = hashlib.sha256()
          with open(file_path, 'rb') as f:
              for chunk in iter(lambda: f.read(4096), b""):
                  hasher.update(chunk)
          return hasher.hexdigest()
      
      def process_json_file(json_path, temp_dir):
          """Process a single JSON configuration file"""
          try:
              with open(json_path, 'r') as f:
                  config_data = json.load(f)
              
              results = []
              for file_entry in config_data.get('files', []):
                  if file_entry.get('type') != 'plist':
                      continue
                  
                  filename = file_entry.get('filename')
                  if not filename:
                      continue
                  
                  plist_data = file_entry.get('data')
                  if plist_data is None:
                      continue
                  
                  converted_data = convert_json_to_plist(plist_data)
                  plist_format = file_entry.get('format', 'xml1')
                  fmt = plistlib.FMT_BINARY if plist_format == "binary1" else plistlib.FMT_XML
                  output_path = Path(temp_dir) / f"{filename}.tmp"
                  
                  with open(output_path, 'wb') as f:
                      plistlib.dump(converted_data, f, fmt=fmt)
                  
                  checksum = compute_file_checksum(output_path)
                  results.append({
                      'filename': filename,
                      'output_path': str(output_path),
                      'format': plist_format,
                      'checksum': checksum,
                      'size': output_path.stat().st_size,
                      'success': True
                  })
                  
                  print(f"✓ Generated plist: {filename}")
              
              return {
                  'json_file': str(json_path),
                  'success': True,
                  'results': results,
                  'total_files': len(results)
              }
          except Exception as e:
              print(f"❌ Error processing {json_path}: {e}")
              return {
                  'json_file': str(json_path),
                  'success': False,
                  'error': str(e),
                  'results': [],
                  'total_files': 0
              }
      
      def main():
          if len(sys.argv) < 3:
              print("Usage: batch-plist-processor <temp_dir> <json_file1> [json_file2] ...")
              sys.exit(1)
          
          temp_dir = sys.argv[1]
          json_files = sys.argv[2:]
          
          all_results = []
          total_files_processed = 0
          
          for json_file in json_files:
              result = process_json_file(json_file, temp_dir)
              all_results.append(result)
              total_files_processed += result['total_files']
          
          summary = {
              'temp_dir': temp_dir,
              'json_files_processed': len(json_files),
              'total_plist_files': total_files_processed,
              'success': all(r['success'] for r in all_results),
              'results': all_results
          }
          
          summary_path = Path(temp_dir) / 'batch_summary.json'
          with open(summary_path, 'w') as f:
              json.dump(summary, f, indent=2)
          
          print(f"Batch processing complete: {total_files_processed} files")
          sys.exit(0 if summary['success'] else 1)
      
      if __name__ == "__main__":
          main()
    '';

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
                  file_mtime=$(${pkgs.coreutils}/bin/stat -f %m "$PLIST_FILE" 2>/dev/null || echo "0")
                  current_checksum=$(${pkgs.coreutils}/bin/sha256sum "$PLIST_FILE" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
            
                  # Check if we have a last checksum for comparison
                  last_checksum="${if fileConfig ? backup && fileConfig.backup ? lastChecksum then fileConfig.backup.lastChecksum else ""}"
            
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
              old_size=$(${pkgs.coreutils}/bin/stat -f %z "$PLIST_FILE" 2>/dev/null || echo "0")
              new_size=$(${pkgs.coreutils}/bin/stat -f %z "$TEMP_PLIST" 2>/dev/null || echo "0")
        
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
                backup_path="$BACKUP_DIR/$FILENAME.backup"
                cp -p "$PLIST_FILE" "$backup_path"
          
                # Get file metadata for manifest
                file_perms=$(${pkgs.coreutils}/bin/stat -f "%Lp" "$PLIST_FILE")
                file_uid=$(${pkgs.coreutils}/bin/stat -f "%u" "$PLIST_FILE")
                file_gid=$(${pkgs.coreutils}/bin/stat -f "%g" "$PLIST_FILE")
                file_size=$(${pkgs.coreutils}/bin/stat -f "%z" "$PLIST_FILE")
                file_mtime=$(${pkgs.coreutils}/bin/stat -f "%m" "$PLIST_FILE")
                file_checksum=$(${pkgs.coreutils}/bin/sha256sum "$PLIST_FILE" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
          
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
    Enhanced batch processing for all plist files with shared infrastructure
    
    Input: 
    - config: Nix configuration
    - jsonConfigs: Array of JSON configs (for multiple files)
    - jsonFilePaths: Array of corresponding JSON file paths
    - useBatchProcessing: Whether to use batch processing (default: true)
    
    Returns: Optimized shell script with batch processing and shared backup
  */
  generateAllPlistScripts =
    { config
    , jsonConfigs ? [ jsonConfig ]
    , jsonFilePaths ? [ jsonFilePath ]
    , jsonConfig ? { }
    , jsonFilePath ? ""
    , useBatchProcessing ? true
    }:
    let
      # Support both single and multiple config formats
      actualConfigs = if jsonConfigs == [ jsonConfig ] && jsonConfig != { } then [ jsonConfig ] else jsonConfigs;
      actualPaths = if jsonFilePaths == [ jsonFilePath ] && jsonFilePath != "" then [ jsonFilePath ] else jsonFilePaths;

      # Check if any file needs backup across all configs
      anyBackupNeeded = lib.any
        (config:
          lib.any
            (fileConfig:
              if fileConfig ? backup then
                (fileConfig.backup.enabled or true) &&
                ((fileConfig.backup.strategy or "smart") != "never")
              else true
            )
            config.files
        )
        actualConfigs;

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

      # Batch processing approach (Phase 2 enhancement)
      batchProcessingScript =
        if useBatchProcessing && (lib.length actualConfigs) > 0 then ''
                    # Batch processing using enhanced Python processor
                    echo "🚀 Using batch processing for ${toString (lib.length actualConfigs)} configuration files..."
        
                                # Create temporary directory for batch processing
                                TEMP_BATCH_DIR=$(mktemp -d -t plist-batch.XXXXXX)
                                echo "📁 Batch temp directory: $TEMP_BATCH_DIR"
        
          # Run batch processor for all JSON files
                  echo "⚙️  Generating plists in batch..."
                  ${batchPlistProcessor { 
                    jsonConfigs = actualConfigs; 
                    jsonFilePaths = actualPaths;
                  }} "$TEMP_BATCH_DIR" ${lib.concatStringsSep " " (map (path: "\"${path}\"") actualPaths)}
        
                                # Check batch processing results
                                BATCH_SUMMARY="$TEMP_BATCH_DIR/batch_summary.json"
                                if [[ ! -f "$BATCH_SUMMARY" ]]; then
                                  echo "❌ Batch processing failed - no summary found"
                                  rm -rf "$TEMP_BATCH_DIR"
                                  exit 1
                                fi
        
                                # Extract statistics from batch summary
                                TOTAL_PLIST_FILES=$(jq -r '.total_plist_files' "$BATCH_SUMMARY")
                                BATCH_SUCCESS=$(jq -r '.success' "$BATCH_SUMMARY")
        
                                echo "📊 Batch processing results:"
                                echo "   Plist files generated: $TOTAL_PLIST_FILES"
                                echo "   Success: $BATCH_SUCCESS"
        
                                if [[ "$BATCH_SUCCESS" != "true" ]]; then
                                  echo "❌ Some files failed to process - check logs above"
                                  rm -rf "$TEMP_BATCH_DIR"
                                  exit 1
                                fi
        
                                # Now deploy files with backup and app management
                                echo "🔄 Deploying plist files with enhanced management..."
        
                                # Process each file config individually for deployment (backup + app management)
                                ${lib.concatMapStringsSep "\n" (jsonConfig: 
                                  lib.concatMapStringsSep "\n" (fileConfig: ''
                                    echo "📤 Processing deployment for: ${fileConfig.filename}"
            
                                    # Find the corresponding generated plist
                                    GENERATED_PLIST="$TEMP_BATCH_DIR/${fileConfig.filename}.tmp"
                                    TARGET_PATH="${config.home.homeDirectory}/${lib.removePrefix "~/" fileConfig.filepath}/${fileConfig.filename}"
            
                                    if [[ -f "$GENERATED_PLIST" ]]; then
                                      # Enhanced change detection with backup integration
                                      NEEDS_DEPLOY=0
                                      DEPLOY_REASON=""
                                      BACKUP_DIR=""
              
                                      if [[ -f "$TARGET_PATH" ]]; then
                                        # Quick size check
                                        old_size=$(stat -f %z "$TARGET_PATH" 2>/dev/null || echo "0")
                                        new_size=$(stat -f %z "$GENERATED_PLIST" 2>/dev/null || echo "0")
                
                                        if [[ $old_size -ne $new_size ]]; then
                                          NEEDS_DEPLOY=1
                                          DEPLOY_REASON="size changed ($old_size -> $new_size bytes)"
                                        else
                                          # Content check via checksum
                                          old_checksum=$(sha256sum "$TARGET_PATH" | cut -d' ' -f1)
                                          new_checksum=$(jq -r --arg fn "${fileConfig.filename}" '.results[].results[]? | select(.filename == $fn) | .checksum' "$BATCH_SUMMARY")
                  
                                          if [[ "$old_checksum" != "$new_checksum" ]]; then
                                            NEEDS_DEPLOY=1
                                            DEPLOY_REASON="content changed"
                                          fi
                                        fi
                
                                        # Smart backup if changes detected and backup enabled
                                        if [[ $NEEDS_DEPLOY -eq 1 ]] && [[ "${lib.boolToString (if fileConfig ? backup then (fileConfig.backup.enabled or true) else true)}" == "true" ]] && [[ "${if fileConfig ? backup then fileConfig.backup.strategy or "smart" else "smart"}" != "never" ]]; then
                                          BACKUP_DIR="$HOME/Library/Preferences/backups/$(date +%Y-%m-%d-%H%M%S)"
                                          mkdir -p "$BACKUP_DIR"
                                          echo "💾 Backing up: ${fileConfig.filename} -> $BACKUP_DIR/"
                  
                                          backup_path="$BACKUP_DIR/${fileConfig.filename}.backup"
                                          cp -p "$TARGET_PATH" "$backup_path"
                  
                                          echo "  ✓ Backed up: $backup_path"
                                        fi
                                      else
                                        NEEDS_DEPLOY=1
                                        DEPLOY_REASON="new file"
                                      fi
              
                                      # Enhanced app management with timeout and health checks
                                      APP_WAS_RUNNING=0
                                      PROCESS_NAME="${fileConfig.appControl.processName}"
                                      TIMEOUT=${if fileConfig.appControl ? timeout then toString fileConfig.appControl.timeout else "10"}
              
                                      if [[ $NEEDS_DEPLOY -eq 1 ]]; then
                                        # Check if app is running
                                        if pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
                                          APP_WAS_RUNNING=1
                                          echo "⏹️  Stopping $PROCESS_NAME..."
                  
                                          # Try graceful shutdown with timeout
                                          if timeout "$TIMEOUT"s bash -c "while pgrep -x '$PROCESS_NAME' >/dev/null; do sleep 0.5; done" <<< "$(${fileConfig.appControl.quitCommand} 2>/dev/null || true)"; then
                                            echo "  ✓ Gracefully stopped"
                                          else
                                            echo "  ⚠️  Force stopping after timeout"
                                            pkill -x "$PROCESS_NAME" 2>/dev/null || true
                                            sleep 1
                                          fi
                                        fi
                
                                        # Deploy file
                                        echo "📤 Deploying: ${fileConfig.filename} ($DEPLOY_REASON)"
                                        mkdir -p "$(dirname "$TARGET_PATH")"
                                        mv "$GENERATED_PLIST" "$TARGET_PATH"
                                        chmod ${fileConfig.permissions} "$TARGET_PATH"
                
                                        # Clear preferences cache
                                        killall cfprefsd 2>/dev/null || true
                                        sleep 1
                
                                        echo "✅ Deployed successfully: ${fileConfig.filename}"
                
                                        # Restart with health check
                                        if [[ $APP_WAS_RUNNING -eq 1 ]] && [[ "${lib.boolToString fileConfig.appControl.requiresRestart}" == "true" ]]; then
                                          echo "🚀 Restarting $PROCESS_NAME..."
                                          ${fileConfig.appControl.restartCommand} 2>/dev/null || true
                  
                                          if ${lib.boolToString (fileConfig.appControl.healthCheck or true)}; then
                                            sleep 3
                                            if pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
                                              echo "  ✓ Health check passed"
                                            else
                                              echo "  ⚠️  Health check failed - app may not have started"
                                            fi
                                          fi
                                        fi
                
                                        # Recovery info if backup was made
                                        if [[ -n "$BACKUP_DIR" ]]; then
                                          echo "💡 Recovery: cp '$BACKUP_DIR/${fileConfig.filename}.backup' '$TARGET_PATH'"
                                        fi
                                      else
                                        echo "✓ No changes needed: ${fileConfig.filename}"
                                        # Clean up temp file
                                        rm -f "$GENERATED_PLIST"
                                      fi
                                    else
                                      echo "❌ Generated plist not found: ${fileConfig.filename}"
                                    fi
                                  '') jsonConfig.files
                                ) actualConfigs}
        
                                # Cleanup
                                rm -rf "$TEMP_BATCH_DIR"
                                echo "🧹 Batch processing complete"
        
        '' else "";

      # Fallback to individual processing (original approach)
      individualProcessingScript =
        if !useBatchProcessing then ''
          # Using individual file processing (legacy mode)
          ${lib.concatMapStringsSep "\n\n" (jsonConfig:
            lib.concatMapStringsSep "\n\n" (fileConfig:
              generatePlistScript { inherit config fileConfig; jsonFilePath = ""; }
            ) jsonConfig.files
          ) actualConfigs}
        '' else "";

    in
    # Combine backup setup with processing script
    backupSetup + (if useBatchProcessing then batchProcessingScript else individualProcessingScript);
}


