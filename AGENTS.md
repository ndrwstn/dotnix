# AGENTS.md - Nix Configuration Repository

## Build/Validation Commands

```bash
# [DEFAULT] Validate flake syntax and structure (SAFE - no system changes)
nix flake check

# [ON DEMAND] Build without switching (SAFE - no system changes, dry run)
# Only when explicitly requested or actively debugging a specific problem
nixos-rebuild build --flake .#<hostname>    # Linux machines
darwin-rebuild build --flake .#<hostname>   # macOS machines

# Test auto-discovery library (optional - tests are rarely needed)
# nix-build tests/auto-discovery-tests.nix
```

### Validation Expectations

- **Documentation-only changes** (`AGENTS.md`, `README.md`, `DARWIN.md`, notes): review for correctness, examples, and internal consistency. Full Nix validation is usually not required.
- **Nix/module/workflow/script changes**: run `nix flake check` as the default validation before considering work complete.
- **Machine-specific configuration changes**: `nix flake check` remains sufficient by default.
- **Builds (dry-run) are on-demand only**: Do not initiate `nixos-rebuild build`, `darwin-rebuild build`, or `nix build` unless explicitly requested or actively debugging a specific build problem.
- **System-aware validation**: Only validate the relevant system for the change:
  - **Darwin changes** → validate on the darwin host (monaco)
  - **NixOS changes** → validate on the relevant NixOS host (never on darwin)
  - **Cross-cutting changes** (lib/, overlays/, flake.nix) → validate on whatever host makes sense (monaco is the default work host)
  - **Never build NixOS configurations on darwin** (`nix build .#nixosConfigurations.*` and `nixos-rebuild build .#<nixos-host>`) unless explicitly told to.
- **Never use `--switch` commands**. Agents may validate and build, but must not apply system changes.

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

#### 3.5 Current Flake/Cache Patterns
- Stable channels are split by platform (`nixpkgs` for NixOS, `nixpkgs-darwin` for Darwin)
- `nixpkgs-unstable` is imported selectively for newer packages
- Shared caches include `nix-community`, `nixvim`, `vicinae`, and `ndrwstn-dotnix` Cachix
- Some inputs intentionally do **not** follow the main nixpkgs pin when upstream cache compatibility matters (for example `vicinae`)

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

## Secrets Management

#### Current Approach
- The repository uses **agenix** for secret management and recipient definitions
- Secret payloads are stored as `.age` files in `secrets/`
- A manual development workflow may still use direct `age` decryption to a temporary `.json` file for easier review/editing
- Any decrypted `.json` files must remain gitignored and must never be committed

#### Secret Structure
```bash
secrets/
├── secrets.nix           # agenix configuration / recipients
├── *.age                 # Encrypted secrets
└── *.json                # Optional decrypted JSON (gitignored, local-only)
```

#### Working with Secrets
1. Prefer updating secrets through the repo's agenix-managed workflow when possible
2. If doing manual development work, decrypt an age file locally: `age -d -i ~/.ssh/id_ed25519 secret.age > secret.json`
3. Edit the JSON file for ease of review
4. Re-encrypt when ready: `age -e -r age1... secret.json > secret.age`
5. Never commit unencrypted JSON files

## Git Commit Naming

#### Required Format
```text
<keyword>(<module>): <description>
```

Examples:
- `update(lock): refresh flake inputs`
- `change(homebrew): replace logi-options with bettermouse`
- `add(nixvim): enable project-local exrc files`
- `fix(vicinae): use upstream nixpkgs pin for cache compatibility`
- `update(insecure/broadcom): update Silver package pin`

#### Allowed Keywords (Closed Vocabulary)
- `add` - introduce a new package, module, machine config, or capability
- `change` - modify existing behavior or configuration without being primarily a fix
- `fix` - correct broken or incorrect behavior
- `remove` - delete a package, module, setting, or capability
- `refactor` - restructure code/config without intended behavior change
- `update` - bump pins, lockfiles, versions, generated values, or routine dependency state
- `docs` - documentation-only changes
- `ci` - changes to automation, workflows, CI configuration, or scripted repo maintenance itself
- `secrets` - encrypted secret definitions, recipients, or secret-related wiring
- `revert` - revert a prior change

Do not invent new leading keywords unless this document is updated first.

#### Module Naming Rules
- Prefer **semantic modules** over raw file paths
- Use short module names that describe the area being changed: `lock`, `homebrew`, `nixvim`, `darwin/dock`, `insecure/broadcom`
- Use slash-separated modules only when the extra specificity is genuinely useful
- Avoid redundant modules like `darwin/homebrew` when `homebrew` already identifies the area
- Use machine names only for machine-specific work: `silver`, `monaco`, `plutonium`, `siberia`
- Use broader modules for cross-cutting areas: `flake`, `overlays`, `users/austin`, `systems/darwin`, `ci`

#### Commit Description Rules
- Keep descriptions concise and specific
- Prefer imperative phrasing: `enable`, `replace`, `remove`, `refresh`, `pin`
- Describe the meaningful change, not just the touched file
- Avoid vague summaries like `update stuff`, `misc fixes`, or `cleanup`

#### Anti-Examples
Avoid messages like:
- `Update flake.lock`
- `Add blueutil and switchaudio-osx to Monaco system packages`
- `Update Silver Broadcom insecure pin`

Rewrite them as:
- `update(lock): refresh flake inputs`
- `add(monaco): add blueutil and switchaudio-osx packages`
- `update(insecure/broadcom): update Silver package pin`

#### Commit Workflow
- **If you created the branch or have made previous commits in it**: commit directly — it's your working branch
- **If unsure whose branch it is or where changes should go**: ask first
- **Do not commit to `master` or `dev` unprompted** — only when explicitly told to

## CI / Automation Commit & PR Naming
- Automated commits and PR titles should follow the same naming convention whenever possible
- For lockfile-only automation, prefer `update(lock): ...`
- Use `ci(...)` only when the change itself is to CI/workflow/automation code
- If automation creates a content update, name the commit after the content change rather than the bot that produced it
- For the Silver Broadcom workflow, prefer `update(insecure/broadcom): update Silver package pin`
- Keep commit and PR titles aligned so generated history stays readable
- Relevant automation currently lives in:
  - `.github/workflows/update-silver-broadcom.yml`
  - `scripts/update-silver-broadcom-pin.py`

## Error Handling & Validation
- Use `lib.warn` for missing optional attributes
- Provide sensible defaults with `defaultSystemType`
- Validate file existence with `builtins.pathExists` before importing
- Use conditional imports for optional configurations

## Important Constraints
- **NEVER use `--switch` commands** - system modifications must be done manually by user
- **Builds (dry-run) are on-demand only**: Do not initiate `nixos-rebuild build`, `darwin-rebuild build`, or `nix build` unless explicitly requested or actively debugging a specific build problem.
- **Auto-discovery tests are optional** - the system is stable and rarely changes
- **Always validate Nix/module/workflow/script changes** with `nix flake check` before considering work complete
