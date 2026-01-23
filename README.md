# Nix Flake

NixOS and nix-darwin configurations using agenix for secret management.

## Setup

### NixOS

```bash
# Clone repo
git clone https://github.com/ndrwstn/dotnix
cd dotnix

# Create machine configuration (if new machine)
mkdir -p machines/<hostname>
cp machines/siberia/configuration.nix machines/<hostname>/
# Edit configuration.nix as needed

# Build and switch
nixos-rebuild switch --flake .#<hostname>
# Hostname is automatically set from flake after first build
```

### Darwin (macOS)

#### Quick Start

```bash
# 1. Install Homebrew (required for nix-darwin configuration)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install standard Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# 3. Set hostname
sudo scutil --set ComputerName <hostname>
sudo scutil --set LocalHostName <hostname>
sudo scutil --set HostName <hostname>

# 4. Bootstrap nix-darwin (requires sudo for system.defaults)
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake github:ndrwstn/dotnix#<hostname>
```

**⚠️ Important:**

- Do NOT use Determinate Nix installer
- Your macOS username must be `austin` or `jessica` (or create a new user config)
- See **[DARWIN.md](DARWIN.md)** for detailed installation instructions and troubleshooting

#### Supported Machines

- **Monaco** - aarch64-darwin (Apple Silicon)
- **Plutonium** - x86_64-darwin (Intel)
- **Silver** - x86_64-darwin (Intel)

#### Updates

```bash
# After initial setup (use sudo for system.defaults)
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>
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
