# Automated Insecure Package Updates

This directory contains the automation system for detecting and updating insecure packages in the Nix flake repository.

## Overview

The system automatically:

- Detects insecure packages using `nix eval`
- Updates `permittedInsecurePackages` lists in machine configurations
- Validates changes with `nix flake check`
- Creates automated PRs with updates
- Auto-merges successful updates

## Files

- `update-insecure-packages.py` - Main automation script
- `utils/nix_helpers.py` - Nix-specific utilities
- `utils/config_parser.py` - Configuration file parsing
- `utils/validation.py` - Build validation utilities

## Usage

### Manual Execution

```bash
# Dry run (show what would be updated)
python scripts/update-insecure-packages.py --dry-run --verbose

# Actually perform updates
python scripts/update-insecure-packages.py --verbose
```

### Automated Execution

The system runs daily via GitHub Actions (`.github/workflows/update-insecure-packages.yml`):

- **Schedule**: Daily at 2 AM UTC
- **Trigger**: Manual dispatch available
- **Validation**: Full flake checks + build validation
- **Auto-merge**: Enabled for successful updates

## How It Works

1. **Discovery**: Scans all machine configurations for `permittedInsecurePackages`
2. **Detection**: Uses `nix eval` to check if packages are still insecure
3. **Update**: Updates configuration files with current insecure package lists
4. **Lock Update**: Runs `nix flake update` to refresh dependencies
5. **Validation**: Ensures configurations build successfully
6. **PR Creation**: Creates automated PR with changes
7. **Auto-merge**: Merges PR if all validations pass

## Extensible Framework

The system is designed to handle any insecure package, not just broadcom-sta:

- **Package Detection**: Automatic discovery of insecure packages
- **Version Management**: Tracks package versions across machines
- **Platform Awareness**: Only validates affected machine types
- **Security Focus**: Prioritizes security updates over version bumps

## Configuration

### GitHub Actions Settings

- **Auto-merge**: Enabled for successful validations
- **Validation Level**: Configurable (flake check vs full builds)
- **Dry Run**: Available for testing without changes

### Security Considerations

- **Validation Required**: All changes must pass validation before merging
- **Rollback Ready**: Clear commit history for easy reversion
- **Platform Isolation**: Issues with one machine don't affect others
- **Manual Override**: Auto-merge can be disabled if needed

## Troubleshooting

### Common Issues

1. **Flake check fails**: Review error messages and fix configuration issues
2. **Build timeouts**: Some machines may take longer to build
3. **Permission issues**: Ensure GitHub token has necessary permissions

### Debugging

Use the `--dry-run --verbose` flags to see what would be changed without making actual modifications:

```bash
python scripts/update-insecure-packages.py --dry-run --verbose
```

### Manual Intervention

If automated updates fail:

1. Check the workflow logs for error details
2. Run manual updates with dry-run first
3. Fix any configuration issues
4. Re-run the workflow or create manual PR

## Future Enhancements

- **Security Notifications**: Slack/Discord alerts for failed updates
- **Version Tracking**: Historical tracking of insecure package versions
- **Advanced Validation**: Build testing for specific affected machines
- **Package Discovery**: Automatic detection of new insecure packages
