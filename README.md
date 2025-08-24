# Nix Flake

NixOS and nix-darwin configurations using agenix for secret management.

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

# Build and switch
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

## Secret Management with agenix

This flake uses [agenix](https://github.com/ryantm/agenix) for secret management. Secrets are encrypted using SSH host keys.

### Adding Secrets

```bash
# Install agenix
nix-shell -p agenix

# Edit secrets (agenix automatically handles encryption/decryption)
agenix -e <secret-name>

# Secrets are defined in secrets/secrets.nix and encrypted to SSH host keys
# No manual key generation needed - agenix uses existing SSH host keys
```

### SSH Host Keys

agenix uses SSH host keys from `/etc/ssh/ssh_host_*` for encryption/decryption. These are automatically generated when SSH is enabled on the system.

## Legacy SOPS Files

Previous SOPS configuration files have been moved to `sops_old/` directory for reference. The system now exclusively uses agenix for secret management.
