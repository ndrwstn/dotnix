#!/usr/bin/env bash

# Test script to generate one machine's Syncthing secrets and verify the JSON structure

set -euo pipefail

MACHINE="monaco"
TEMP_DIR=$(mktemp -d)
OUTPUT_DIR="./test-secrets"

echo "Testing Syncthing secret generation for $MACHINE..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate Syncthing certificates
echo "Generating certificates..."
syncthing generate --home "$TEMP_DIR" >/dev/null 2>&1

# Extract device ID
DEVICE_ID=$(syncthing --home "$TEMP_DIR" --device-id 2>/dev/null)
echo "Device ID: $DEVICE_ID"

# Read certificate and key files
CERT_CONTENT=$(cat "$TEMP_DIR/cert.pem")
KEY_CONTENT=$(cat "$TEMP_DIR/key.pem")

# Get GUI credentials from 1Password
echo "Getting GUI credentials..."
GUI_USER=$(op item get "syncthing gui" --vault Private --fields username 2>/dev/null)
GUI_PASSWORD=$(op item get "syncthing gui" --vault Private --fields password --reveal 2>/dev/null)

# Generate bcrypt hash
GUI_PASSWORD_HASH=$(htpasswd -nbB "" "$GUI_PASSWORD" | cut -d: -f2)

echo "GUI User: $GUI_USER"
echo "GUI Password Hash: ${GUI_PASSWORD_HASH:0:20}..."

# Create JSON structure
JSON_CONTENT=$(jq -n \
	--arg deviceId "$DEVICE_ID" \
	--arg cert "$CERT_CONTENT" \
	--arg key "$KEY_CONTENT" \
	--arg gui_user "$GUI_USER" \
	--arg gui_password "$GUI_PASSWORD_HASH" \
	'{
        deviceId: $deviceId,
        cert: $cert,
        key: $key,
        gui: {
            user: $gui_user,
            password: $gui_password
        }
    }')

# Save JSON to output directory
echo "$JSON_CONTENT" >"$OUTPUT_DIR/syncthing-$MACHINE.json"

echo "JSON saved to $OUTPUT_DIR/syncthing-$MACHINE.json"
echo "JSON structure:"
jq -r 'keys[]' "$OUTPUT_DIR/syncthing-$MACHINE.json"
echo "GUI keys:"
jq -r '.gui | keys[]' "$OUTPUT_DIR/syncthing-$MACHINE.json"

# Test extraction
echo "Testing extraction..."
mkdir -p "$OUTPUT_DIR/extracted"
jq -r '.deviceId' "$OUTPUT_DIR/syncthing-$MACHINE.json" >"$OUTPUT_DIR/extracted/device-id"
jq -r '.cert' "$OUTPUT_DIR/syncthing-$MACHINE.json" >"$OUTPUT_DIR/extracted/cert.pem"
jq -r '.key' "$OUTPUT_DIR/syncthing-$MACHINE.json" >"$OUTPUT_DIR/extracted/key.pem"
jq -r '.gui.user' "$OUTPUT_DIR/syncthing-$MACHINE.json" >"$OUTPUT_DIR/extracted/gui-user"
jq -r '.gui.password' "$OUTPUT_DIR/syncthing-$MACHINE.json" >"$OUTPUT_DIR/extracted/gui-password"

echo "Extracted files:"
ls -la "$OUTPUT_DIR/extracted/"

echo "Device ID from extracted file: $(cat "$OUTPUT_DIR/extracted/device-id")"
echo "GUI user from extracted file: $(cat "$OUTPUT_DIR/extracted/gui-user")"

# Cleanup
rm -rf "$TEMP_DIR"

echo "Test completed successfully!"
