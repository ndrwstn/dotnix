{ lib, pkgs }:

rec {
  /*
    Generate a shell script that deploys a plist file from JSON configuration
    
    Input fileConfig structure:
    {
      type = "plist";
      format = "binary1" | "xml1";
      filename = "com.example.app.plist";
      filepath = "~/Library/Preferences";
      permissions = "600";
      appControl = {
        processName = "AppName";
        quitCommand = "killall AppName";
        restartCommand = "open -a AppName";
        requiresRestart = true;
      };
      data = { };
    }
    
    Returns: Shell script that:
    1. Converts JSON to plist using Python plistlib
    2. Checks for changes using cmp
    3. Conditionally quits app if running AND changes detected
    4. Deploys to target location with correct permissions
    5. Conditionally restarts app if it was running
  */
  generatePlistScript = { config, fileConfig, jsonFilePath }:
    pkgs.writeShellScript "deploy-plist-${fileConfig.filename}" ''
            set -euo pipefail

            # Expand filepath (handle ~ prefix)
            PLIST_DIR="${config.home.homeDirectory}/${lib.removePrefix "~/" fileConfig.filepath}"
            PLIST_FILE="$PLIST_DIR/${fileConfig.filename}"
            TEMP_PLIST=$(mktemp "$PLIST_DIR/.${fileConfig.filename}.XXXXXX")

            # Ensure target directory exists
            mkdir -p "$PLIST_DIR"

            # Generate plist from JSON data using Python plistlib (pass vars as env)
            PLIST_OUTPUT_FILE="$TEMP_PLIST" \
            PLIST_JSON_SOURCE="${jsonFilePath}" \
            PLIST_FORMAT="${fileConfig.format}" \
            ${pkgs.python3}/bin/python3 <<'PYTHON_EOF'
            import json
            import plistlib
            import os
            import base64
            from datetime import datetime

            def convert_json_to_plist(obj):
                """Recursively convert JSON to plist-compatible objects with type handling"""
                if isinstance(obj, dict):
                    # Check for explicit type annotations
                    if "__type" in obj and "value" in obj:
                        if obj["__type"] == "date":
                            # Parse ISO 8601 date string
                            return datetime.fromisoformat(obj["value"].replace('Z', '+00:00'))
                        elif obj["__type"] == "data":
                            # Decode base64 data
                            return base64.b64decode(obj["value"])
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

            # Read JSON directly from source file (avoids Nix serialization issues)
            with open(json_source, 'r') as f:
                config_data = json.load(f)

            # Extract plist data from the first file entry
            plist_data = config_data['files'][0]['data']

            # Convert with type handling
            converted_data = convert_json_to_plist(plist_data)

            # Determine plist format
            fmt = plistlib.FMT_BINARY if plist_format == "binary1" else plistlib.FMT_XML

            # Write plist file
            with open(output_file, 'wb') as f:
                plistlib.dump(converted_data, f, fmt=fmt)

            print(f"Generated plist: {output_file}")
            PYTHON_EOF

            # Check if plist changed (change detection)
            NEEDS_DEPLOY=0
            if [[ -f "$PLIST_FILE" ]]; then
              if ! cmp -s "$TEMP_PLIST" "$PLIST_FILE"; then
                NEEDS_DEPLOY=1
                echo "✓ Changes detected: ${fileConfig.filename}"
              else
                echo "✓ No changes: ${fileConfig.filename}"
                rm -f "$TEMP_PLIST"
                exit 0
              fi
            else
              NEEDS_DEPLOY=1
              echo "✓ New plist: ${fileConfig.filename}"
            fi

            # Check if app is running (only if changes need deployment)
            APP_WAS_RUNNING=0
            if [[ $NEEDS_DEPLOY -eq 1 ]] && pgrep -x "${fileConfig.appControl.processName}" >/dev/null 2>&1; then
              APP_WAS_RUNNING=1
              echo "  → Stopping ${fileConfig.appControl.processName}..."
              ${fileConfig.appControl.quitCommand} 2>/dev/null || true
              sleep 2
            fi

      # Deploy new plist
      if [[ $NEEDS_DEPLOY -eq 1 ]]; then
        echo "  → Deploying ${fileConfig.filename}..."
        mv "$TEMP_PLIST" "$PLIST_FILE"
        chmod ${fileConfig.permissions} "$PLIST_FILE"
  
        # Clear macOS preferences cache to force reload
        echo "  → Clearing preferences cache..."
        killall cfprefsd 2>/dev/null || true
  
        echo "  ✓ Deployed successfully"
      fi

            # Restart app if it was running and restart is required
            if [[ $APP_WAS_RUNNING -eq 1 ]] && [[ "${lib.boolToString fileConfig.appControl.requiresRestart}" == "true" ]]; then
              echo "  → Restarting ${fileConfig.appControl.processName}..."
              ${fileConfig.appControl.restartCommand} 2>/dev/null || true
              echo "  ✓ Restarted successfully"
            fi
    '';

  /*
    Generate deployment scripts for all plist files in a JSON config
    
    Input: Full JSON config with "files" array, and source JSON file path
    Returns: Concatenated shell script for all files
  */
  generateAllPlistScripts = { config, jsonConfig, jsonFilePath }:
    lib.concatMapStringsSep "\n"
      (fileConfig: ''
        ${generatePlistScript { inherit config fileConfig jsonFilePath; }}
      '')
      jsonConfig.files;
}
