#!/usr/bin/env bash

# Generate Syncthing secrets for all machines
# This script creates JSON secrets containing deviceId, cert, key, and GUI credentials

set -euo pipefail

# Configuration
MACHINES=("monaco" "plutonium" "siberia" "silver")
TEMP_DIR=$(mktemp -d)
SECRETS_DIR="./secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
	rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

# Check dependencies
check_dependencies() {
	log "Checking dependencies..."

	if ! command -v syncthing &>/dev/null; then
		error "syncthing command not found. Please install Syncthing."
		exit 1
	fi

	if ! command -v op &>/dev/null; then
		error "op command not found. Please install 1Password CLI."
		exit 1
	fi

	if ! command -v htpasswd &>/dev/null; then
		error "htpasswd command not found. Please install apache2-utils."
		exit 1
	fi

	if ! command -v jq &>/dev/null; then
		error "jq command not found. Please install jq."
		exit 1
	fi

	if ! command -v agenix &>/dev/null; then
		error "agenix command not found. Please install agenix."
		exit 1
	fi
}

# Get GUI credentials from 1Password
get_gui_credentials() {
	log "Retrieving GUI credentials from 1Password..."

	local username
	local password
	local password_hash

	username=$(op item get "syncthing gui" --vault Private --fields username 2>/dev/null) || {
		error "Failed to read username from 1Password. Make sure you're signed in and the item exists."
		exit 1
	}

	password=$(op item get "syncthing gui" --vault Private --fields password --reveal 2>/dev/null) || {
		error "Failed to read password from 1Password. Make sure you're signed in and the item exists."
		exit 1
	}

	# Generate bcrypt hash using htpasswd
	password_hash=$(htpasswd -nbB "" "$password" | cut -d: -f2)

	echo "$username:$password_hash"
}

# Generate certificates and device ID for a machine
generate_machine_secrets() {
	local machine="$1"
	local machine_dir="$TEMP_DIR/$machine"

	log "Generating secrets for $machine..."

	mkdir -p "$machine_dir"

	# Generate Syncthing certificates
	syncthing generate --home "$machine_dir" >/dev/null 2>&1

	# Extract device ID
	local device_id
	device_id=$(syncthing --home "$machine_dir" --device-id 2>/dev/null)

	# Read certificate and key files
	local cert_content
	local key_content
	cert_content=$(cat "$machine_dir/cert.pem")
	key_content=$(cat "$machine_dir/key.pem")

	# Get GUI credentials
	local gui_creds
	gui_creds=$(get_gui_credentials)
	local gui_user="${gui_creds%%:*}"
	local gui_password="${gui_creds#*:}"

	# Create JSON structure
	local json_content
	json_content=$(jq -n \
		--arg deviceId "$device_id" \
		--arg cert "$cert_content" \
		--arg key "$key_content" \
		--arg gui_user "$gui_user" \
		--arg gui_password "$gui_password" \
		'{
            deviceId: $deviceId,
            cert: $cert,
            key: $key,
            gui: {
                user: $gui_user,
                password: $gui_password
            }
        }')

	# Write JSON to temporary file
	echo "$json_content" >"$machine_dir/syncthing-secrets.json"

	log "Generated secrets for $machine (Device ID: ${device_id:0:7}...)"
}

# Encrypt secrets using agenix
encrypt_secrets() {
	log "Encrypting secrets with agenix..."

	for machine in "${MACHINES[@]}"; do
		local json_file="$TEMP_DIR/$machine/syncthing-secrets.json"
		local age_file="syncthing-$machine.age"

		if [[ -f "$json_file" ]]; then
			log "Encrypting secrets for $machine..."
			# Change to secrets directory to run agenix
			(cd "$SECRETS_DIR" && agenix -e "$age_file" --identity ~/.ssh/austin_agenix <"$json_file")
			log "Created $SECRETS_DIR/$age_file"
		else
			error "JSON file not found for $machine"
			exit 1
		fi
	done
}

# Main execution
main() {
	log "Starting Syncthing secrets generation..."

	check_dependencies

	# Create secrets directory if it doesn't exist
	mkdir -p "$SECRETS_DIR"

	# Generate secrets for all machines
	for machine in "${MACHINES[@]}"; do
		generate_machine_secrets "$machine"
	done

	# Show summary
	log "Generated secrets for ${#MACHINES[@]} machines:"
	for machine in "${MACHINES[@]}"; do
		local device_id
		device_id=$(jq -r '.deviceId' "$TEMP_DIR/$machine/syncthing-secrets.json")
		echo "  $machine: ${device_id:0:7}...${device_id: -7}"
	done

	# Encrypt secrets
	encrypt_secrets

	log "Syncthing secrets generation completed successfully!"
	log "Next steps:"
	log "1. Update machine secrets.nix files to reference the new secrets"
	log "2. Update secrets/secrets.nix to include plutonium and siberia"
	log "3. Replace users/austin/syncthing.nix with the new consolidated module"
}

# Run main function
main "$@"
