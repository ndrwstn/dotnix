<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# AGENTS.md - Nix Configuration Repository

## Build/Validation Commands

```bash
# Validate flake syntax and structure (SAFE - no system changes)
nix flake check

# Build configuration without switching (DRY RUN - no system changes)
nixos-rebuild build --flake .#<hostname>    # Linux machines
darwin-rebuild build --flake .#<hostname>   # macOS machines

# Test auto-discovery library (optional - tests are rarely needed)
# nix-build tests/auto-discovery-tests.nix
```

## Code Architecture & Patterns

### Repository Structure
```
/
├── lib/                    # Shared libraries (auto-discovery.nix)
├── machines/               # Per-machine configurations
│   ├── <hostname>/
│   │   ├── configuration.nix    # Main machine config
│   │   ├── secrets.nix         # Machine-specific secrets
│   │   └── hardware-configuration.nix  # Optional hardware config
├── systems/                # OS-specific system modules
│   ├── common/             # Shared across all systems
│   ├── darwin/             # macOS-specific modules
│   └── nixos/              # NixOS-specific modules
├── users/                  # User configurations
│   └── <username>/
│       ├── default.nix     # Main user config
│       ├── darwin/         # macOS-specific user config
│       ├── nixos/          # NixOS-specific user config
│       └── nixvim/         # Neovim configuration
├── overlays/               # Package overlays
└── secrets/                # Encrypted secrets
```

### Key Design Patterns

#### 1. Auto-Discovery System
The repository uses a custom auto-discovery library (`lib/auto-discovery.nix`) that:
- Discovers valid machine directories by checking for `configuration.nix`
- Extracts system types from `_astn.machineSystem` metadata or `SYSTEM_TYPE:` comments
- Merges configurations from multiple directories using `discoverAndMergeConfigs`
- Supports case-insensitive directory matching

#### 2. Machine Metadata Pattern
Machines declare their system type using a custom namespace that doesn't affect system configuration:
```nix
# Machine metadata (used by flake.nix, does not affect system configuration)
_astn.machineSystem = "x86_64-linux";  # or "aarch64-darwin"
```

#### 3. Modular Configuration Structure
- **System-level**: Common settings → OS-specific settings → Machine-specific settings
- **User-level**: Common packages → OS-specific packages → Machine-specific packages
- **Secrets**: Common secrets → Machine-specific secrets (layered approach)

#### 4. Conditional Imports
Use `lib.mkIf` for OS-specific configurations:
```nix
(lib.mkIf pkgs.stdenv.isDarwin (import ./darwin { inherit config pkgs lib; }))
(lib.mkIf (!pkgs.stdenv.isDarwin) (import ./nixos { inherit config pkgs lib; }))
```

### Code Style Guidelines

#### Nix Formatting
- 2-space indentation (no tabs)
- Line length: 80-100 characters preferred
- Function parameters on separate lines with leading commas
- Use `lib` for nixpkgs.lib consistently

#### Naming Conventions
- Machine names: lowercase (e.g., `siberia`, `monaco`)
- Custom namespace: `_astn.*` for machine metadata
- File names: kebab-case (e.g., `auto-discovery.nix`)
- Attribute names: camelCase for options, snake_case for config

#### Import Patterns
```nix
{ config, pkgs, lib, ... }: {
  imports = [
    ./secrets.nix
    ./hardware-configuration.nix  # if exists
  ];
  
  # Machine metadata (doesn't affect system config)
  _astn.machineSystem = "x86_64-linux";
}
```

### Secrets Management

#### Current Approach
- Uses `age` encryption (not agenix for development work)
- Secrets directory contains both `.age` files and `.json` files (gitignored)
- For development: decrypt `.age` → edit `.json` → review changes → re-encrypt

#### Secret Structure
```bash
secrets/
├── secrets.nix           # agenix configuration (who can decrypt what)
├── *.age                 # Encrypted secrets
└── *.json                # Unencrypted JSON (gitignored, for development)
```

#### Working with Secrets
1. Decrypt age file: `age -d -i ~/.ssh/id_ed25519 secret.age > secret.json`
2. Edit the JSON file for ease of review
3. Re-encrypt when ready: `age -e -r age1... secret.json > secret.age`
4. Never commit unencrypted JSON files

### Error Handling & Validation
- Use `lib.warn` for missing optional attributes
- Provide sensible defaults with `defaultSystemType`
- Validate file existence with `builtins.pathExists` before importing
- Use conditional imports for optional configurations

### Important Constraints
- **NEVER use `--switch` commands** - system modifications must be done manually by user
- **Test builds first** with `nixos-rebuild build` or `darwin-rebuild build`
- **Auto-discovery tests are optional** - the system is stable and rarely changes
- **Always validate** with `nix flake check` before considering work complete