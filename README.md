# NX - NIX Configuration

This repository contains the Nix configuration for multiple systems, including both NixOS and Darwin (macOS) machines.

## Features

- Multi-system configuration (NixOS and Darwin)
- Home Manager integration
- Automatic machine discovery
- Shared configuration across systems
- User-specific configurations
- Secrets management with sops-nix

## Structure

- `flake.nix` - Main entry point for the configuration
- `lib/` - Custom Nix functions and utilities
- `machines/` - Machine-specific configurations
  - `<hostname>/configuration.nix` - Main configuration for a machine
  - `<hostname>/*.sops.yaml` - Machine-specific encrypted secrets
- `overlays/` - Nixpkgs overlays
- `systems/` - Shared system configurations
  - `common/` - Configuration shared across all systems
  - `common/*.sops.yaml` - Shared encrypted secrets
  - `darwin/` - Darwin-specific configuration
  - `nixos/` - NixOS-specific configuration
- `users/` - User-specific configurations
  - `<username>/default.nix` - User configuration
  - `<username>/*.sops.yaml` - User-specific encrypted secrets
- `docs/` - Documentation
  - `sops.md` - Documentation for secrets management

## Usage

### Building a System

```bash
# Build a NixOS system
nix build .#nixosConfigurations.<hostname>.system

# Build a Darwin system
nix build .#darwinConfigurations.<hostname>.system
```

### Applying a Configuration

```bash
# Apply a NixOS configuration
nixos-rebuild switch --flake .#<hostname>

# Apply a Darwin configuration
darwin-rebuild switch --flake .#<hostname>
```

### Checking the Configuration

```bash
# Check the flake
nix flake check
```

## Secrets Management

This repository uses sops-nix for secrets management. Secrets are stored alongside their related configuration files using the `.sops.yaml` suffix.

### Setting Up Sops

1. Install sops and age:
   ```bash
   nix-shell -p sops age
   ```

2. Generate an age key:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

3. Add your public key to `.sops.yaml`:
   ```yaml
   keys:
     - &user_yourname age1...  # Your public key from age-keygen -y
   ```

### Creating and Using Secrets

1. Create a secret file next to its configuration:
   ```yaml
   # Example: users/austin/api_keys.sops.yaml
   api_keys:
     github: "your_github_token"
   ```

2. Encrypt the file:
   ```bash
   sops -e -i users/austin/api_keys.sops.yaml
   ```

3. Reference the secret in your Nix configuration:
   ```nix
   sops.secrets."api_keys/github" = {
     sopsFile = ./api_keys.sops.yaml;
     key = "api_keys.github";
   };
   ```

4. Use the secret:
   ```nix
   home.sessionVariables = {
     GITHUB_TOKEN = "$(cat ${config.sops.secrets.\"api_keys/github\".path})";
   };
   ```

See [docs/sops.md](docs/sops.md) for more detailed information.

## License

This project is licensed under the MIT License - see the LICENSE file for details.