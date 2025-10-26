# Project Context

## Purpose

Declarative, reproducible configuration for personal and lab machines using Nix flakes. Unify NixOS and macOS (nix-darwin) into a modular, layered system with auto-discovery, strict secrets handling, and simple, auditable builds.

## Tech Stack

- Nix flakes, nixpkgs, NixOS modules, nix-darwin
- Homebrew (managed via nix-darwin), age (encryption), agenix (dev workflow only)
- User/application configs: nixvim, tmux, syncthing, atuin, ghostty, texlive, 1Password (NixOS module)

## Project Conventions

### Code Style

- Nix: 2-space indent, 80–100 cols, kebab-case filenames, camelCase attrs
- Machine names lowercase; custom metadata namespace `_astn.*`
- Follow import patterns and lib usage shown in AGENTS.md

### Architecture Patterns

- Auto-discovery (lib/auto-discovery.nix): discovers machines with configuration.nix, merges configs, supports case-insensitive matching, uses `_astn.machineSystem` or SYSTEM_TYPE comments
- Layered config:
  - Systems: systems/common → systems/{darwin|nixos} → machines/<host>
  - Users: users/<name>/default.nix → OS-specific → app/tool modules
  - Secrets: secrets/\*.age (common) → machines/<host>/secrets.nix (host)
- Conditional imports with lib.mkIf for OS-specific logic
- Machine metadata pattern:
  - \_astn.machineSystem = "x86_64-linux" | "aarch64-darwin" (non-functional metadata)

### Testing Strategy

- Always validate before considering changes complete:
  - nix flake check
  - Dry builds per impacted host: nixos-rebuild build --flake .#<host> or darwin-rebuild build --flake .#<host>
- When touching lib/auto-discovery.nix, optionally run tests in tests/auto-discovery-tests.nix
- Treat build success for all targeted hosts as required; never use --switch in automation

### Git Workflow

- Branch from master using <type>/<name> (feat, fix, chore, docs, refactor, test, build, ci)
- Conventional Commits; small, atomic commits; no secrets in history
- PR review before merge; never force push
- See AGENTS.md for detailed branching, commit, and review rules

## Domain Context

- Hosts: monaco, plutonium, silver (active); siberia (disabled config present)
- OS targets: NixOS (x86_64-linux) and macOS (aarch64-darwin) supported
- Users: austin, jessica with OS-specific and app-specific modules
- Secrets: age-encrypted files in secrets/ and machines/\*/secrets.nix gate wiring; .json dev copies are gitignored

## Important Constraints

- No system changes in automation: only dry builds; never --switch
- Never commit unencrypted secrets; .json files are local/dev only
- Use lib.warn and safe defaults; check file existence before importing
- Naming: lowercase machines, kebab-case files, camelCase attrs; follow repo patterns

## External Dependencies

- Nix, nixpkgs, nixos-rebuild, darwin-rebuild
- age (encryption), agenix (for access policy; dev flow only)
- Homebrew on macOS
- 1Password integration on NixOS (systems/nixos/1password.nix)
- SSH keys for GitHub/Gitea (secrets/ssh/\*)

Refer to AGENTS.md for build/validation commands, repository structure, and detailed patterns.
