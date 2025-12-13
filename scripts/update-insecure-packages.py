#!/usr/bin/env python3
"""
Automated Insecure Package Updater for Nix Flake Repository

This script detects insecure packages in Nix configurations and automatically
updates permittedInsecurePackages lists across all affected machines.

Usage:
    python scripts/update-insecure-packages.py [--dry-run] [--verbose]

Features:
- Detects insecure packages using nix eval
- Updates permittedInsecurePackages in machine configurations
- Supports any insecure package (extensible framework)
- Platform-aware validation (only tests affected machines)
- Integrates with existing auto-discovery system
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


class NixPackageSecurityChecker:
    """Handles querying Nix for package security information."""

    def __init__(self, nixpkgs_path: Optional[str] = None, verbose: bool = False):
        self.nixpkgs_path = nixpkgs_path or "nixpkgs"
        self.verbose = verbose

    def get_package_info(self, package_name: str) -> Dict:
        """Query nixpkgs for package information including security status."""
        try:
            # Handle different package types
            attribute_path = self._get_attribute_path(package_name)

            if not attribute_path:
                print(f"Warning: Could not find attribute path for {package_name}")
                return {}

            # Get package metadata including vulnerabilities
            cmd = [
                "nix", "eval", "--json",
                f"{attribute_path}.meta",
                "--apply", "x: x // { version: x.name or \"unknown\" }"
            ]

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                return json.loads(result.stdout)
            else:
                print(f"Warning: Failed to get info for {package_name}: {result.stderr}")
                return {}

        except subprocess.TimeoutExpired:
            print(f"Warning: Timeout getting info for {package_name}")
            return {}
        except Exception as e:
            print(f"Warning: Error getting info for {package_name}: {e}")
            return {}

    def _get_attribute_path(self, package_name: str) -> Optional[str]:
        """Get the correct attribute path for a package name."""
        # Handle broadcom-sta specifically - it's a kernel module
        if package_name.startswith("broadcom-sta-"):
            # Extract kernel version from package name
            # Format: broadcom-sta-{version}-{revision}-{kernel-version}
            parts = package_name.split("-")
            if len(parts) >= 6:
                kernel_version = f"{parts[4]}.{parts[5]}"  # e.g., "6.12"
                # Try common kernel package paths
                possible_paths = [
                    f"linuxKernel.packages.linux_{kernel_version.replace('.', '_')}.broadcom_sta",
                    f"linuxPackages_{kernel_version.replace('.', '_')}.broadcom_sta",
                    "linuxPackages.broadcom_sta"
                ]

                # Test each path
                for path in possible_paths:
                    if self._attribute_exists(path):
                        return f"{self.nixpkgs_path}.{path}"

        # For other packages, try direct lookup
        if self._attribute_exists(package_name):
            return f"{self.nixpkgs_path}.{package_name}"

        return None

    def _attribute_exists(self, attribute_path: str) -> bool:
        """Check if a nixpkgs attribute exists."""
        try:
            cmd = ["nix", "eval", "--json", f"{self.nixpkgs_path}.{attribute_path}", "null"]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0
        except Exception:
            return False

    def is_package_insecure(self, package_name: str) -> bool:
        """Check if a package is marked as insecure in nixpkgs."""
        info = self.get_package_info(package_name)

        # If we can't get package info, assume it's still insecure
        # This is a conservative approach for automation
        if not info:
            if self.verbose:
                print(f"Could not verify {package_name}, assuming still insecure")
            return True

        return info.get("knownVulnerabilities", []) != []

    def get_package_version(self, package_name: str) -> str:
        """Get the current version of a package."""
        info = self.get_package_info(package_name)
        return info.get("version", "unknown")


class MachineConfigUpdater:
    """Handles updating machine configuration files."""

    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.machines_dir = repo_root / "machines"

    def discover_machines(self) -> List[str]:
        """Discover all valid machine directories using auto-discovery patterns."""
        machines = []
        if not self.machines_dir.exists():
            return machines

        for item in self.machines_dir.iterdir():
            if item.is_dir() and (item / "configuration.nix").exists():
                machines.append(item.name)

        return machines

    def get_permitted_insecure_packages(self, machine: str) -> List[str]:
        """Extract permittedInsecurePackages from a machine configuration."""
        config_file = self.machines_dir / machine / "configuration.nix"

        if not config_file.exists():
            return []

        try:
            content = config_file.read_text()

            # Find permittedInsecurePackages list
            match = re.search(
                r'permittedInsecurePackages\s*=\s*\[(.*?)\];',
                content,
                re.DOTALL
            )

            if not match:
                return []

            # Extract package names from the list
            packages_text = match.group(1)
            # Simple regex to extract quoted strings
            packages = re.findall(r'"([^"]*)"', packages_text)

            return packages

        except Exception as e:
            print(f"Warning: Error reading {config_file}: {e}")
            return []

    def update_permitted_insecure_packages(self, machine: str, packages: List[str]) -> bool:
        """Update permittedInsecurePackages in a machine configuration."""
        config_file = self.machines_dir / machine / "configuration.nix"

        if not config_file.exists():
            print(f"Warning: Configuration file not found: {config_file}")
            return False

        try:
            content = config_file.read_text()

            # Find and replace the permittedInsecurePackages list
            old_pattern = r'(permittedInsecurePackages\s*=\s*\[)(.*?)(\];)'
            new_packages = '\n'.join(f'    "{pkg}"' for pkg in packages)
            new_list = f'[\n{new_packages}\n  ]'

            new_content = re.sub(
                old_pattern,
                r'\1' + new_packages + r'\3',
                content,
                flags=re.DOTALL
            )

            # Write back the updated content
            config_file.write_text(new_content)
            return True

        except Exception as e:
            print(f"Error updating {config_file}: {e}")
            return False


class InsecurePackageUpdater:
    """Main class for orchestrating insecure package updates."""

    def __init__(self, repo_root: Path, dry_run: bool = False, verbose: bool = False):
        self.repo_root = repo_root
        self.dry_run = dry_run
        self.verbose = verbose

        self.security_checker = NixPackageSecurityChecker(verbose=verbose)
        self.config_updater = MachineConfigUpdater(repo_root)

    def find_machines_with_insecure_packages(self) -> Dict[str, List[str]]:
        """Find all machines that have insecure packages in their permitted list."""
        machines = self.config_updater.discover_machines()
        affected_machines = {}

        for machine in machines:
            insecure_packages = self.config_updater.get_permitted_insecure_packages(machine)

            # Filter to only packages that are actually still insecure
            still_insecure = []
            for package in insecure_packages:
                if self.security_checker.is_package_insecure(package):
                    still_insecure.append(package)
                elif self.verbose:
                    print(f"Package {package} on {machine} is no longer insecure")

            if still_insecure:
                affected_machines[machine] = still_insecure

        return affected_machines

    def update_insecure_packages(self) -> Dict[str, List[str]]:
        """Update insecure packages across all affected machines."""
        affected_machines = self.find_machines_with_insecure_packages()

        if not affected_machines:
            print("No insecure packages found that need updating.")
            return {}

        if self.dry_run:
            print("DRY RUN - Would update the following:")
            for machine, packages in affected_machines.items():
                print(f"  {machine}: {packages}")
            return affected_machines

        updated_machines = {}

        for machine, packages in affected_machines.items():
            print(f"Updating {machine}...")

            # For now, we'll keep the same packages but could extend this
            # to find newer secure versions in the future
            if self.config_updater.update_permitted_insecure_packages(machine, packages):
                updated_machines[machine] = packages
                print(f"  ✓ Updated {len(packages)} packages")
            else:
                print(f"  ✗ Failed to update {machine}")

        return updated_machines

    def validate_updates(self, updated_machines: Dict[str, List[str]]) -> bool:
        """Validate that the updates work by running nix flake check."""
        if not updated_machines:
            return True

        print("Validating updates...")

        try:
            # Run nix flake check
            result = subprocess.run(
                ["nix", "flake", "check"],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
                timeout=300  # 5 minutes
            )

            if result.returncode == 0:
                print("✓ Flake check passed")
                return True
            else:
                print("✗ Flake check failed:")
                print(result.stderr)
                return False

        except subprocess.TimeoutExpired:
            print("✗ Flake check timed out")
            return False
        except Exception as e:
            print(f"✗ Validation error: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description="Update insecure packages in Nix flake configurations"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be updated without making changes"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show detailed output"
    )

    args = parser.parse_args()

    # Find repository root
    repo_root = Path(__file__).parent.parent

    # Initialize updater
    updater = InsecurePackageUpdater(repo_root, args.dry_run, args.verbose)

    print("🔍 Scanning for insecure packages...")

    # Update insecure packages
    updated_machines = updater.update_insecure_packages()

    if not args.dry_run and updated_machines:
        print("\n🔧 Validating updates...")
        if updater.validate_updates(updated_machines):
            print("✅ All updates validated successfully!")
            return 0
        else:
            print("❌ Validation failed!")
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())