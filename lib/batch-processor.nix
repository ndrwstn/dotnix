{ lib, pkgs }:

let
  # Enhanced Python batch processor for handling multiple plist files efficiently
  batchPlistProcessor = { jsonConfigs, jsonFilePaths }:
    pkgs.writeScript "batch-plist-processor" ''
      #!/usr/bin/env python3
      """
      Batch Plist Processor
      Processes multiple JSON configuration files to generate plists efficiently
      """
      
      import json
      import plistlib
      import os
      import sys
      import base64
      from datetime import datetime
      from pathlib import Path
      import hashlib
      
      def convert_json_to_plist(obj, type_handlers=None):
          """Enhanced type conversion for plist compatibility with extensible handlers"""
          if type_handlers is None:
              type_handlers = {
                  'date': lambda v: datetime.fromisoformat(v.replace('Z', '+00:00')),
                  'data': lambda v: base64.b64decode(v),
                  'bool': lambda v: v.lower() in ("true", "1", "yes") if isinstance(v, str) else bool(v),
                  'int': lambda v: int(v),
                  'float': lambda v: float(v),
                  'url': lambda v: str(v),
                  'uuid': lambda v: str(v),
                  'string': lambda v: str(v),
              }
          
          if isinstance(obj, dict):
              # Check for explicit type annotations
              if "__type" in obj and "value" in obj:
                  type_handler = obj["__type"]
                  value = obj["value"]
                  
                  if type_handler in type_handlers:
                      try:
                          return type_handlers[type_handler](value)
                      except (ValueError, TypeError) as e:
                          print(f"⚠️  Warning: Failed to convert {type_handler}: {e}", file=sys.stderr)
                          return value
                  else:
                      print(f"⚠️  Warning: Unknown type handler: {type_handler}", file=sys.stderr)
                      return value
              # Recursively process dict
              return {k: convert_json_to_plist(v, type_handlers) for k, v in obj.items()}
          elif isinstance(obj, list):
              return [convert_json_to_plist(item, type_handlers) for item in obj]
          else:
              return obj
      
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
              # Read JSON configuration
              with open(json_path, 'r') as f:
                  config_data = json.load(f)
              
              results = []
              
              for file_entry in config_data.get('files', []):
                  if file_entry.get('type') != 'plist':
                      continue
                  
                  filename = file_entry.get('filename')
                  if not filename:
                      continue
                  
                  # Get data for this file
                  plist_data = file_entry.get('data')
                  if plist_data is None:
                      print(f"⚠️  Warning: No data found for filename: {filename}", file=sys.stderr)
                      continue
                  
                  # Convert with enhanced type handling
                  converted_data = convert_json_to_plist(plist_data)
                  
                  # Determine output format
                  plist_format = file_entry.get('format', 'xml1')
                  fmt = plistlib.FMT_BINARY if plist_format == "binary1" else plistlib.FMT_XML
                  
                  # Generate output filename
                  output_path = Path(temp_dir) / f"{filename}.tmp"
                  
                  # Write plist file
                  with open(output_path, 'wb') as f:
                      plistlib.dump(converted_data, f, fmt=fmt)
                  
                  # Calculate checksum for change detection
                  checksum = compute_file_checksum(output_path)
                  
                  results.append({
                      'filename': filename,
                      'output_path': str(output_path),
                      'format': plist_format,
                      'checksum': checksum,
                      'size': output_path.stat().st_size,
                      'success': True
                  })
                  
                  print(f"✓ Generated plist: {filename} ({output_path.stat().st_size} bytes)")
              
              return {
                  'json_file': str(json_path),
                  'success': True,
                  'results': results,
                  'total_files': len(results)
              }
              
          except Exception as e:
              print(f"❌ Error processing {json_path}: {e}", file=sys.stderr)
              return {
                  'json_file': str(json_path),
                  'success': False,
                  'error': str(e),
                  'results': [],
                  'total_files': 0
              }
      
      def main():
          if len(sys.argv) < 3:
              print("Usage: batch-plist-processor <temp_dir> <json_file1> [json_file2] ...", file=sys.stderr)
              sys.exit(1)
          
          temp_dir = sys.argv[1]
          json_files = sys.argv[2:]
          
          print(f"🔄 Processing {len(json_files)} JSON configuration files...")
          
          all_results = []
          total_files_processed = 0
          
          for json_file in json_files:
              print(f"\n📁 Processing: {os.path.basename(json_file)}")
              result = process_json_file(json_file, temp_dir)
              all_results.append(result)
              total_files_processed += result['total_files']
          
          # Output results summary as JSON for shell processing
          summary = {
              'temp_dir': temp_dir,
              'json_files_processed': len(json_files),
              'total_plist_files': total_files_processed,
              'success': all(r['success'] for r in all_results),
              'results': all_results
          }
          
          # Write summary to temp file for shell script to read
          summary_path = Path(temp_dir) / 'batch_summary.json'
          with open(summary_path, 'w') as f:
              json.dump(summary, f, indent=2)
          
          print(f"\n📊 Batch processing complete:")
          print(f"   JSON files: {len(json_files)}")
          print(f"   Plist files generated: {total_files_processed}")
          print(f"   Success: {summary['success']}")
          print(f"   Summary written to: {summary_path}")
          
          # Exit with appropriate code
          sys.exit(0 if summary['success'] else 1)
      
      if __name__ == "__main__":
          main()
    '';

  # Parallel deployment manager for independent files
  parallelDeployer = { deploymentJobs, maxJobs ? 4 }:
    let
      deployScript = pkgs.writeShellScript "parallel-deployer" ''
        set -euo pipefail
        
        # Configuration
        MAX_JOBS=${toString maxJobs}
        TEMP_DIR="$1"
        
        echo "🚀 Starting parallel deployment (max $MAX_JOBS concurrent jobs)..."
        
        # Function to deploy a single plist file
        deploy_file() {
          local job_json="$1"
          local temp_dir="$2"
          
          # Parse job JSON using minimal shell parsing
          local filename=$(jq -r '.filename' "$job_json")
          local output_path=$(jq -r '.output_path' "$job_json")
          local format=$(jq -r '.format' "$job_json")
          local checksum=$(jq -r '.checksum' "$job_json")
          local size=$(jq -r '.size' "$job_json")
          
          # Extract target path and permissions from job info
          local target_path=$(jq -r '.target_path // empty' "$job_json")
          local permissions=$(jq -r '.permissions // "600"' "$job_json")
          
          if [[ -z "$target_path" ]]; then
            echo "❌ No target_path specified for $filename"
            return 1
          fi
          
          echo "📤 Deploying: $filename"
          
          # Enhanced change detection
          NEEDS_DEPLOY=0
          DEPLOY_REASON=""
          
          if [[ -f "$target_path" ]]; then
            # Quick size check first
            local old_size=$(stat -f %z "$target_path" 2>/dev/null || echo "0")
            
            if [[ $old_size -ne $size ]]; then
              NEEDS_DEPLOY=1
              DEPLOY_REASON="size changed ($old_size -> $size bytes)"
            else
              # Size same, check content via checksum
              local old_checksum=$(sha256sum "$target_path" | cut -d' ' -f1)
              if [[ "$old_checksum" != "$checksum" ]]; then
                NEEDS_DEPLOY=1
                DEPLOY_REASON="content changed"
              fi
            fi
          else
            NEEDS_DEPLOY=1
            DEPLOY_REASON="new file"
          fi
          
          if [[ $NEEDS_DEPLOY -eq 1 ]]; then
            # Ensure target directory exists
            mkdir -p "$(dirname "$target_path")"
            
            # Deploy with atomic move
            mv "$output_path" "$target_path"
            chmod "$permissions" "$target_path"
            
            echo "✅ Deployed: $filename ($DEPLOY_REASON)"
            
            # Write deployment status back to temp file
            echo "{\"filename\":\"$filename\",\"deployed\":true,\"reason\":\"$DEPLOY_REASON\"}" > "$temp_dir/deploy_status_$(basename "$filename" .plist).json"
          else
            echo "✓ No changes needed: $filename"
            # Clean up temp file
            rm -f "$output_path"
            
            # Write no-change status
            echo "{\"filename\":\"$filename\",\"deployed\":false,\"reason\":\"no_changes\"}" > "$temp_dir/deploy_status_$(basename "$filename" .plist).json"
          fi
        }
        
        # Export function for subshell
        export -f deploy_file
        
        # Read batch summary and create deployment jobs
        BATCH_SUMMARY="$TEMP_DIR/batch_summary.json"
        
        if [[ ! -f "$BATCH_SUMMARY" ]]; then
          echo "❌ Batch summary not found: $BATCH_SUMMARY"
          exit 1
        fi
        
        # Create deployment jobs as individual JSON files
        job_count=0
        jq -r '.results[] | .results[]? | @base64' "$BATCH_SUMMARY" | while IFS= read -r base64_data; do
          if [[ $((job_count % MAX_JOBS)) -eq 0 ]] && [[ $job_count -gt 0 ]]; then
            # Wait for current batch to complete
            wait
          fi
          
          # Decode and create job file
          job_data=$(echo "$base64_data" | base64 --decode)
          filename=$(echo "$job_data" | jq -r '.filename')
          
          # Add target path to job data (need to derive from original config)
          # For now, use a default path - this will be enhanced in Phase 4
          target_path="$HOME/Library/Preferences/$filename"
          
          # Create job JSON file
          job_file="$TEMP_DIR/job_$(basename "$filename" .plist).json"
          echo "$job_data" | jq --arg target_path "$target_path" '. + {target_path: $target_path}' > "$job_file"
          
          # Deploy in background
          deploy_file "$job_file" "$TEMP_DIR" &
          
          job_count=$((job_count + 1))
        done
        
        # Wait for all remaining jobs
        wait
        
        echo "\n🎉 Parallel deployment complete!"
        
        # Generate deployment summary
        DEPLOYED_COUNT=$(find "$TEMP_DIR" -name "deploy_status_*.json" -exec grep -l '"deployed":true' {} \; | wc -l)
        SKIPPED_COUNT=$(find "$TEMP_DIR" -name "deploy_status_*.json" -exec grep -l '"deployed":false' {} \; | wc -l)
        
        echo "   Deployed: $DEPLOYED_COUNT files"
        echo "   Skipped: $SKIPPED_COUNT files"
      '';
    in
    deployScript;

in
{
  inherit batchPlistProcessor parallelDeployer;
}
