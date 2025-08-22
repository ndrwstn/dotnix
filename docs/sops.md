# Secrets Management with sops-nix

This document describes how to use sops-nix for secrets management in this Nix configuration.

## Overview

[sops-nix](https://github.com/Mic92/sops-nix) is a tool that integrates Mozilla's [sops](https://github.com/mozilla/sops) (Secrets OPerationS) with Nix/NixOS. It allows you to securely store sensitive information in your Nix configuration using age encryption.

## Setup

### Fresh NixOS Installation Bootstrap

For fresh NixOS installations that don't have age keys yet, the configuration is designed to gracefully handle missing keys:

1. **Initial System Build**: The system will build successfully even without age keys, as secrets are conditionally loaded only when the key file exists.

2. **Generate Machine Age Key**: After the initial build, the system will automatically generate an age key at `/var/lib/sops-nix/key.txt` due to the `age.generateKey = true` setting.

3. **Extract the Public Key**: Once the system is running, extract the machine's public key:

   ```bash
   sudo age-keygen -y /var/lib/sops-nix/key.txt
   ```

4. **Add Key to Configuration**: Add the machine's public key to the `.sops.yaml` file in the repository and re-encrypt relevant secrets.

5. **Rebuild System**: After updating the secrets, rebuild the system to enable secret-dependent features like WiFi configuration.

### Prerequisites

1. Install sops and age:

   ```bash
   nix-shell -p sops age
   ```

2. Generate an age key:

   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

3. Extract the public key from the age key:
   ```bash
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

### Configuration

1. Update the `.sops.yaml` file in the repository root with your age public key:

   ```yaml
   keys:
     - &user_austin age1yubikey1... # Replace with your public key
   ```

2. For each machine, generate a machine-specific age key and add it to the `.sops.yaml` file.

## Directory Structure

- `.sops.yaml` - Configuration file for sops
- Secrets are stored alongside their related configuration files:
  - `machines/<machine_name>/*.sops.yaml` - Machine-specific secrets
    - Example: `machines/monaco/wifi.sops.yaml`
  - `users/<username>/*.sops.yaml` - User-specific secrets
    - Example: `users/austin/api_keys.sops.yaml`
    - Example: `users/austin/ssh.sops.yaml`
  - `systems/common/*.sops.yaml` - Shared secrets for all systems
    - Example: `systems/common/common.sops.yaml`

## Usage

### Creating and Editing Secrets

1. Create a new YAML file in the same directory as the related configuration:

   ```yaml
   # Example: users/austin/api_keys.sops.yaml
   api_keys:
     github: "your_github_token"
     aws: "your_aws_key"
   ```

2. Encrypt the file using sops:

   ```bash
   sops -e -i users/austin/api_keys.sops.yaml
   ```

3. To edit an encrypted file:

   ```bash
   sops users/austin/api_keys.sops.yaml
   ```

4. In Neovim, you can use the following keybindings:
   - `<leader>usd` - Decrypt the current file
   - `<leader>use` - Encrypt the current file

### Using Secrets in NixOS Configuration

1. Define the secret in your configuration:

   ```nix
   sops.secrets."api_keys/github" = {
     sopsFile = ./api_keys.sops.yaml;
     key = "api_keys.github";
   };
   ```

2. Use the secret in your configuration:

   ```nix
   # For environment variables
   home.sessionVariables = {
     GITHUB_TOKEN = "$(cat ${config.sops.secrets.\"api_keys/github\".path})";
   };

   # For service configuration
   services.someService.passwordFile = config.sops.secrets."api_keys/github".path;
   ```

## Key Management

### Adding a New User

1. Generate an age key for the user
2. Add the public key to the `.sops.yaml` file
3. Re-encrypt all relevant secrets to include the new user's key

### Adding a New Machine

1. Generate an age key for the machine
2. Add the public key to the `.sops.yaml` file
3. Create machine-specific secrets in the `machines/<machine_name>/` directory with the `.sops.yaml` suffix
4. Encrypt the secrets with the machine's key

### Key Rotation

1. Generate a new age key
2. Add the new public key to the `.sops.yaml` file
3. Re-encrypt all relevant secrets with the new key
4. Remove the old key from the `.sops.yaml` file
5. Re-encrypt all secrets again to remove the old key

## Troubleshooting

### Common Issues

1. **Error: Failed to get data key: 0 successful groups**

   - Ensure your age key is correctly configured
   - Check that the `.sops.yaml` file includes your public key
   - Verify that the encrypted file was created with your key

2. **Error: No matching keys found**

   - The file was encrypted with a different key
   - Re-encrypt the file with your key

3. **Error: Failed to load config: no such file or directory**

   - Ensure the `.sops.yaml` file exists in the repository root

4. **Fresh Installation Issues**
   - If you're setting up a fresh NixOS installation, the system should build successfully even without age keys
   - Secrets and secret-dependent features (like WiFi) will be disabled until keys are properly configured
   - Follow the "Fresh NixOS Installation Bootstrap" process above to properly set up secrets

### Bootstrap Process for New Machines

1. **Initial Build**: Clone the repository and build the system configuration. It will work without secrets.
2. **Key Generation**: The system automatically generates an age key on first boot.
3. **Key Extraction**: Extract the public key and add it to `.sops.yaml`.
4. **Secret Re-encryption**: Re-encrypt relevant secrets to include the new machine's key.
5. **Final Rebuild**: Rebuild the system to enable all secret-dependent features.

## Best Practices

1. **Never commit unencrypted secrets**

   - Always encrypt secrets before committing
   - Use the `.gitignore` file to exclude unencrypted secrets

2. **Use separate keys for different users and machines**

   - Each user should have their own key
   - Each machine should have its own key

3. **Organize secrets by purpose**

   - Use a clear directory structure
   - Group related secrets together

4. **Limit access to secrets**

   - Only encrypt secrets with the keys of users who need access
   - Use machine-specific keys for machine-specific secrets

5. **Regularly rotate keys**
   - Generate new keys periodically
   - Re-encrypt secrets with new keys

## References

- [sops-nix GitHub Repository](https://github.com/Mic92/sops-nix)
- [sops GitHub Repository](https://github.com/mozilla/sops)
- [age GitHub Repository](https://github.com/FiloSottile/age)
- [NixOS Wiki: Sops](https://nixos.wiki/wiki/Sops)
