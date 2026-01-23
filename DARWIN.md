# macOS (Darwin) Installation Guide

This guide covers installing and managing nix-darwin on macOS systems using this flake configuration.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Verification](#verification)
- [Future Updates](#future-updates)
- [Troubleshooting](#troubleshooting)
- [Complete Nix Removal](#complete-nix-removal)

## Prerequisites

### System Requirements

- macOS 10.15 (Catalina) or later
- Administrator access (sudo privileges)
- Internet connection

### User Account Requirements

**IMPORTANT:** Before running the bootstrap command, ensure your macOS user account matches one of the users defined in this flake.

**Supported users:**

- `austin` - Full configuration with packages and dotfiles
- `jessica` - Minimal configuration

**To check your current username:**

```bash
whoami
```

**If you need to set up a new user:**

You have two options:

1. **Use an existing user configuration** - Make sure your macOS username matches `austin` or `jessica` when setting up macOS
2. **Create a new user directory** - Copy and modify an existing user configuration:

   ```bash
   # Clone the repo first
   git clone https://github.com/ndrwstn/dotnix ~/dotnix
   cd ~/dotnix

   # Copy existing user config
   cp -r users/austin users/$(whoami)

   # Edit the new user's default.nix
   # Change home.username and home.homeDirectory to match your username
   ```

### Supported Machines

This flake supports the following machine configurations:

| Machine   | Architecture     | System Type    |
| --------- | ---------------- | -------------- |
| Monaco    | Apple Silicon M2 | aarch64-darwin |
| Plutonium | Intel x86_64     | x86_64-darwin  |
| Silver    | Intel x86_64     | x86_64-darwin  |

## Initial Setup

### Step 1: Install Homebrew

This configuration uses Homebrew for GUI applications and system utilities. Install it first:

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Important:** After installation, follow any on-screen instructions to add Homebrew to your PATH. For Apple Silicon Macs, you may need to run:

```bash
# Apple Silicon only - add Homebrew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Verify Homebrew is installed:

```bash
brew --version
# Should show: Homebrew 5.x.x or later
```

### Step 2: Install Standard Nix

**⚠️ IMPORTANT:** Use the official Nix installer, NOT Determinate Nix. Determinate Nix conflicts with nix-darwin's Nix management.

```bash
# Download and run the official multi-user Nix installer
sh <(curl -L https://nixos.org/nix/install) --daemon
```

**What this does:**

- Creates `/nix` directory (APFS volume on modern macOS)
- Installs Nix package manager
- Sets up the Nix daemon for multi-user support
- Configures shell initialization

### Step 3: Restart Your Shell

Close and reopen your terminal, or source the Nix profile manually:

```bash
# For zsh (default shell on macOS)
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# For bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Step 4: Verify Nix Installation

```bash
# Check Nix version
nix --version
# Expected output: nix (Nix) 2.x.x

# Check Nix environment
echo $NIX_PATH
# Should show something like: nixpkgs=...

# Test Nix command
nix-env --version
# Should show version without errors
```

### Step 5: Set Hostname

Your hostname must match one of the machine directories in `machines/`. Case-insensitive matching is supported.

```bash
# Replace <hostname> with: monaco, plutonium, or silver
sudo scutil --set ComputerName <hostname>
sudo scutil --set LocalHostName <hostname>
sudo scutil --set HostName <hostname>

# Verify all three are set correctly
echo "ComputerName: $(scutil --get ComputerName)"
echo "LocalHostName: $(scutil --get LocalHostName)"
echo "HostName: $(scutil --get HostName)"
```

**Example for Monaco:**

```bash
sudo scutil --set ComputerName Monaco
sudo scutil --set LocalHostName Monaco
sudo scutil --set HostName Monaco
```

### Step 5.5: Verify User Configuration (IMPORTANT)

Before bootstrapping, verify your username has a corresponding configuration:

```bash
# Check your username
whoami
# Should output: austin (or jessica)

# Verify user directory exists in the flake (if you cloned it)
ls ~/dotnix/users/$(whoami) 2>/dev/null && echo "✓ User config found" || echo "Note: Will check when bootstrap runs"
```

**If your username is NOT `austin` or `jessica`**, you must either:

1. Create a macOS user account named `austin` and log in as that user, OR
2. Create a new user configuration directory (see [Prerequisites > User Account Requirements](#user-account-requirements))

### Step 6: Bootstrap nix-darwin

This step installs nix-darwin and applies your machine configuration in one command:

```bash
# Install directly from GitHub (requires sudo for system.defaults)
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake github:ndrwstn/dotnix#<hostname>
```

Replace `<hostname>` with your machine name (e.g., `monaco`, `plutonium`, `silver`).

**Why sudo?** This configuration uses `system.defaults` to manage macOS system preferences (Finder settings, screensaver, etc.). As of nix-darwin 25.11, these system-level changes require root privileges for security reasons.

**Note:** The `--extra-experimental-features "nix-command flakes"` flag enables flakes for this command. After nix-darwin is installed, flakes will be permanently enabled in your system configuration.

**What this does:**

- Downloads and runs nix-darwin
- Applies your machine configuration from the flake
- Installs home-manager for user-level configuration
- Configures system settings (homebrew, defaults, etc.)
- Sets up shell environment managed by nix-darwin

**This will take several minutes** on first run as it:

- Downloads all necessary packages
- Builds the system configuration
- Sets up home-manager profiles

### Step 7: Clone Repository Locally (Optional)

For easier future updates, clone the repository:

```bash
# Clone to standard location
git clone https://github.com/ndrwstn/dotnix ~/.config/nix
cd ~/.config/nix
```

## Verification

After installation, verify everything is working:

```bash
# 1. Check that nix-darwin is managing the system
which nix
# Expected: /run/current-system/sw/bin/nix (managed by nix-darwin)

# 2. Verify darwin-rebuild is available
darwin-rebuild --help
# Should show help text

# 3. Check system configuration
ls -l /etc/bashrc
# Should be a symlink: /etc/bashrc -> /etc/static/bashrc

# 4. Verify hostname
scutil --get ComputerName
# Should match your machine name

# 5. Check Nix daemon is running
launchctl list | grep nix
# Should show org.nixos.nix-daemon
```

## Future Updates

After initial setup, you can rebuild your system configuration:

### From Local Clone

```bash
# Switch to new configuration (use sudo for system.defaults)
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>

# Build without switching (dry run - sudo not required)
darwin-rebuild build --flake ~/.config/nix#<hostname>

# Check flake validity
cd ~/.config/nix
nix flake check
```

### Directly from GitHub

```bash
# Pull latest changes and rebuild (use sudo for system.defaults)
sudo darwin-rebuild switch --flake github:ndrwstn/dotnix#<hostname>
```

### Update Flake Inputs

```bash
cd ~/.config/nix

# Update all inputs (nixpkgs, home-manager, etc.)
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Rebuild with updated inputs (use sudo for system.defaults)
sudo darwin-rebuild switch --flake .#<hostname>
```

## Troubleshooting

### "System activation must now be run as root"

**Error:** `darwin-rebuild: system activation must now be run as root`

**Cause:** Your configuration uses `system.defaults` which requires root privileges to modify macOS system preferences.

**Solution:** Use `sudo` with darwin-rebuild:

```bash
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>
```

**When to use sudo:**

- ✅ Initial bootstrap
- ✅ Any changes to `system.defaults` (Finder, Dock, system preferences)
- ✅ Changes to system-level services (launchd)
- ✅ When in doubt (safest option)

**When sudo is optional:**

- User-level package installations only
- Home-manager configuration changes only
- Building without switching (`darwin-rebuild build`)

### Previously Had Determinate Nix Installed

If you previously used Determinate Nix, you'll see the error:

```
error: Determinate detected, aborting activation
Determinate uses its own daemon to manage the Nix installation that
conflicts with nix-darwin's native Nix management.
```

**Solution:** See [Complete Nix Removal](#complete-nix-removal) below, then start from Step 1.

### Hostname Doesn't Match

**Error:** `error: attribute '<hostname>' missing`

**Solution:** Your hostname must exactly match (case-insensitive) one of:

- `monaco` (or Monaco, MONACO)
- `plutonium` (or Plutonium, PLUTONIUM)
- `silver` (or Silver, SILVER)

Check and fix:

```bash
scutil --get ComputerName
sudo scutil --set ComputerName <correct-hostname>
```

### User Account Not Found

**Error:** Bootstrap fails with errors about missing user configuration or home-manager failures

**Cause:** Your macOS username doesn't match any user directory in `users/`

**Solution:**

Check your username:

```bash
whoami
```

**Option 1:** Use an existing user account (recommended for this flake)

```bash
# Create a new macOS user named 'austin'
# System Settings > Users & Groups > Add Account
# Then log in as 'austin'
```

**Option 2:** Create a new user configuration

```bash
# Clone the repo
git clone https://github.com/ndrwstn/dotnix ~/dotnix
cd ~/dotnix

# Copy an existing user config
cp -r users/austin users/$(whoami)

# Edit users/$(whoami)/default.nix and change:
# - home.username = "your-username";
# - home.homeDirectory = "/Users/your-username";

# Commit and push changes before bootstrapping
git add users/$(whoami)
git commit -m "Add user configuration for $(whoami)"
git push

# Then run bootstrap with your GitHub fork
```

sudo scutil --set ComputerName <correct-hostname>

````

### Nix Command Not Found

**After installation**, if `nix` command is not found:

```bash
# Source Nix profile manually
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Check if Nix is installed
ls -la /nix/var/nix/profiles/default/bin/nix
````

### Permission Issues

**Error:** `error: could not set permissions on '/nix/var/nix/...' to 755`

**Solution:**

```bash
# Fix Nix store permissions
sudo chown -R root:nixbld /nix/store
sudo chmod -R 755 /nix/store
```

### Nix Daemon Not Starting

```bash
# Check daemon status
sudo launchctl list | grep nix-daemon

# Manually load daemon
sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist

# Check daemon logs
sudo cat /var/log/nix-daemon.log
```

### Build Fails with "unfree package"

Some packages require accepting the unfree license. This flake already enables unfree packages, but if you encounter issues:

```bash
# Verify in your machine's configuration.nix
nixpkgs.config.allowUnfree = true;  # Should be present
```

## Complete Nix Removal

If you need to completely remove Nix (for reinstallation or cleanup):

```bash
# 1. Stop all Nix daemons
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/systems.determinate.nix-daemon.plist 2>/dev/null || true

# 2. Remove Nix APFS volume (on modern macOS)
diskutil apfs list | grep "Nix Store"
# If found, delete it:
sudo diskutil apfs deleteVolume "Nix Store"

# 3. Remove Nix directory (if volume removal didn't work or doesn't exist)
sudo rm -rf /nix

# 4. Remove launchd plists
sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo rm -f /Library/LaunchDaemons/systems.determinate.nix-daemon.plist

# 5. Clean user-level Nix configurations
rm -rf ~/.nix-profile
rm -rf ~/.nix-defexpr
rm -rf ~/.nix-channels
rm -rf ~/.config/nix

# 6. Remove shell initialization backups (optional)
sudo rm -f /etc/bashrc.backup-before-nix
sudo rm -f /etc/zshrc.backup-before-nix

# 7. Verify removal
ls -la /nix  # Should show: No such file or directory
which nix    # Should show: nix not found
```

**After complete removal**, start fresh from [Step 1: Install Homebrew](#step-1-install-homebrew).

## Additional Notes

### Why Not Determinate Nix?

Determinate Nix is a third-party Nix installer with enhanced features, but it manages its own Nix installation via a separate daemon. This conflicts with nix-darwin, which expects to manage Nix itself. Using standard Nix ensures compatibility and consistency across all Darwin machines.

### Architecture Differences

- **Apple Silicon (M1/M2/M3)**: Uses `aarch64-darwin` packages
- **Intel**: Uses `x86_64-darwin` packages

The flake automatically selects the correct architecture based on your machine configuration's `_astn.machineSystem` attribute.

### What Gets Managed by nix-darwin?

Once installed, nix-darwin manages:

- System packages (installed to `/run/current-system/sw/bin/`)
- System settings (keyboard, trackpad, dock, etc.) - **requires sudo**
- Homebrew packages and casks (declarative)
- Shell environment (`/etc/bashrc`, `/etc/zshrc`)
- User configurations via home-manager

### Updating Homebrew Packages

Homebrew packages are declared in `systems/darwin/homebrew.nix` and user-specific `users/<username>/darwin/homebrew.nix`. To update:

```bash
# Let nix-darwin manage homebrew (use sudo for system.defaults)
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>

# Homebrew updates are handled declaratively
# No need to run `brew update` or `brew upgrade` manually
```

## Getting Help

- **Nix Manual**: https://nixos.org/manual/nix/stable/
- **nix-darwin Manual**: https://daiderd.com/nix-darwin/manual/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **This Repository**: https://github.com/ndrwstn/dotnix
