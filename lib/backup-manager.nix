# Backup Manager for macOS Preference Files

# lib/backup-manager.nix
{ lib, pkgs }:

let
  # Generate backup timestamp in consistent format
  generateTimestamp = builtins.currentTime;

  # Create backup directory path with timestamp
  createBackupDirPath = timestamp:
    "$HOME/Library/Preferences/backups/${toString timestamp}";

  # Generate checksum for file change detection
  generateChecksum = file: ''
    ${pkgs.coreutils}/bin/sha256sum "$1" | ${pkgs.coreutils}/bin/cut -d' ' -f1
  '';

  # Check if file has local changes since last backup
  hasLocalChanges = { originalFile, lastBackupTime }: ''
    # Check if file exists
    if [[ ! -f "$1" ]]; then
      return 0  # File doesn't exist, no backup needed
    fi
    
    # Get file modification time
    local file_mtime=$(${pkgs.coreutils}/bin/stat -f %m "$1" 2>/dev/null || echo "0")
    local backup_time="${toString lastBackupTime}"
    
    # Check if file was modified after last known good backup
    if [[ $file_mtime -gt $backup_time ]]; then
      # File was modified, check if content actually changed
      if [[ -n "$2" ]]; then
        # Compare with last backup checksum if provided
        local current_checksum=$(${pkgs.coreutils}/bin/sha256sum "$1" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
        if [[ "$current_checksum" != "$2" ]]; then
          return 0  # File has local changes
        fi
      else
        # No checksum to compare, assume changes exist
        return 0
      fi
    fi
    
    return 1  # No local changes detected
  '';

  # Create backup directory structure
  createBackupStructure = timestamp: ''
        local backup_dir="$HOME/Library/Preferences/backups/${toString timestamp}"
        mkdir -p "$backup_dir"
    
        # Create initial manifest
        cat > "$backup_dir/manifest.json" << 'EOF'
    {
      "timestamp": "${toString timestamp}",
      "trigger": "nix-darwin rebuild",
      "files": {},
      "metadata": {
        "hostname": "$(hostname)",
        "user": "$(whoami)",
        "nix_version": "${pkgs.nix.version}"
      }
    }
    EOF
    
        echo "$backup_dir"
  '';

  # Backup individual file with metadata
  backupFile = { fileConfig, timestamp, originalPath }: ''
        local original_path="${originalPath}"
        local backup_dir="$HOME/Library/Preferences/backups/${toString timestamp}"
        local backup_filename="${fileConfig.filename}.backup"
        local backup_path="$backup_dir/$backup_filename"
    
        if [[ -f "$original_path" ]]; then
          # Create backup with original permissions
          cp -p "$original_path" "$backup_path"
      
          # Get file metadata
          local file_perms=$(${pkgs.coreutils}/bin/stat -f "%Lp" "$original_path")
          local file_uid=$(${pkgs.coreutils}/bin/stat -f "%u" "$original_path")
          local file_gid=$(${pkgs.coreutils}/bin/stat -f "%g" "$original_path")
          local file_size=$(${pkgs.coreutils}/bin/stat -f "%z" "$original_path")
          local file_mtime=$(${pkgs.coreutils}/bin/stat -f "%m" "$original_path")
          local file_checksum=$(${pkgs.coreutils}/bin/sha256sum "$original_path" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
      
          # Create JSON entry for manifest
          local json_entry='
    {
      "original_path": "'$original_path'",
      "backup_path": "'$backup_path'",
      "permissions": "'$file_perms'",
      "uid": '$file_uid',
      "gid": '$file_gid',
      "size": '$file_size',
      "mtime": '$file_mtime',
      "checksum": "'$file_checksum'",
      "backup_reason": "local_changes_detected"
    }'
      
          # Add to manifest using jq if available, otherwise append to file
          if command -v jq >/dev/null 2>&1; then
            local temp_manifest=$(mktemp)
            jq --arg filename "${fileConfig.filename}" --argjson entry "$json_entry" \
              '.files[$filename] = $entry' "$backup_dir/manifest.json" > "$temp_manifest" && \
              mv "$temp_manifest" "$backup_dir/manifest.json"
          else
            # Fallback: simple append (less elegant but works)
            echo "  \"${fileConfig.filename}\": $json_entry," >> "$backup_dir/manifest.tmp"
          fi
      
          return 0
        else
          return 1  # File doesn't exist, no backup needed
        fi
  '';

in
{
  inherit
    generateTimestamp
    createBackupDirPath
    generateChecksum
    hasLocalChanges
    createBackupStructure
    backupFile;
}
