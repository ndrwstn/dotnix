# Nix Flake

NixOS and nix-darwin configurations using SOPS.

## Setup

### NixOS

```bash
# Clone repo
git clone https://github.com/ndrwstn/dotnix
cd nx-nix

# Create machine configuration (if new machine)
mkdir -p machines/<hostname>
cp machines/siberia/configuration.nix machines/<hostname>/
# Edit configuration.nix as needed

# Build (works without secrets, WiFi etc disabled until keys added)
nixos-rebuild switch --flake .#<hostname>
# Hostname is automatically set from flake after first build
```

### Darwin (macOS)

```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Set hostname for auto-discovery
sudo scutil --set ComputerName <hostname>
sudo scutil --set LocalHostName <hostname>
sudo scutil --set HostName <hostname>

# Clone and build
git clone https://github.com/ndrwstn/dotnix
cd nx-nix
darwin-rebuild switch --flake .#<hostname>
```

## Generate Keys

```bash
# Install tools
nix-shell -p sops age

# Generate personal age key (one-time)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt  # Get public key

# For NixOS: Extract machine key (auto-generated after first build)
sudo age-keygen -y /var/lib/sops-nix/key.txt  # Copy this output

# Add keys to .sops.yaml and update secrets
# Edit .sops.yaml to add new keys under "keys:" section
# Re-encrypt secrets for new machine access:
sops updatekeys systems/common/wifi.sops.yaml
sops updatekeys machines/<hostname>/syncthing.sops.yaml

# Rebuild to enable secrets
nixos-rebuild switch --flake .  # or darwin-rebuild
```
