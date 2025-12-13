"""
Validation utilities for testing Nix configurations after updates.
"""

import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Set


class NixValidator:
    """Handles validation of Nix configurations and builds."""

    def __init__(self, repo_root: Path):
        self.repo_root = repo_root

    def check_flake(self) -> bool:
        """Run nix flake check on the repository."""
        try:
            result = subprocess.run(
                ["nix", "flake", "check"],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
                timeout=300  # 5 minutes
            )
            return result.returncode == 0
        except subprocess.TimeoutExpired:
            print("Flake check timed out")
            return False
        except Exception as e:
            print(f"Flake check error: {e}")
            return False

    def build_machine_config(self, machine: str, system_type: str = "auto") -> bool:
        """Build a specific machine configuration."""
        try:
            if system_type == "auto":
                # Try to determine system type from machine config
                system_type = self._detect_system_type(machine)

            if system_type == "nixos":
                cmd = ["nixos-rebuild", "build", "--flake", f".#{machine}"]
            elif system_type == "darwin":
                cmd = ["darwin-rebuild", "build", "--flake", f".#{machine}"]
            else:
                print(f"Unknown system type for {machine}: {system_type}")
                return False

            result = subprocess.run(
                cmd,
                cwd=self.repo_root,
                capture_output=True,
                text=True,
                timeout=600  # 10 minutes
            )
            return result.returncode == 0
        except subprocess.TimeoutExpired:
            print(f"Build timed out for {machine}")
            return False
        except Exception as e:
            print(f"Build error for {machine}: {e}")
            return False

    def _detect_system_type(self, machine: str) -> str:
        """Detect the system type for a machine."""
        # Read the machine configuration to find the system type
        config_file = self.repo_root / "machines" / machine / "configuration.nix"
        if not config_file.exists():
            return "unknown"

        try:
            content = config_file.read_text()
            # Look for indicators of system type
            if "boot.loader.systemd-boot" in content or "boot.loader.grub" in content:
                return "nixos"
            elif "system.stateVersion = 4;" in content or "homebrew" in content:
                return "darwin"
        except Exception:
            pass

        return "unknown"

    def validate_machines(self, machines: List[str]) -> Dict[str, bool]:
        """Validate multiple machines and return results."""
        results = {}

        print(f"Validating {len(machines)} machine(s)...")

        for machine in machines:
            print(f"  Building {machine}...")
            success = self.build_machine_config(machine)
            results[machine] = success
            status = "✓" if success else "✗"
            print(f"    {status} {machine}")

        return results

    def validate_flake_only(self) -> bool:
        """Quick validation that only checks flake syntax."""
        print("Running flake check...")
        success = self.check_flake()
        status = "✓" if success else "✗"
        print(f"  {status} Flake check")
        return success


class ValidationManager:
    """Manages validation workflow for insecure package updates."""

    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.validator = NixValidator(repo_root)

    def validate_updates(self, updated_machines: Dict[str, List[str]],
                        validation_level: str = "full") -> bool:
        """
        Validate updates based on the specified level.

        Args:
            updated_machines: Dict of machine -> packages that were updated
            validation_level: "flake" for quick check, "full" for complete builds
        """
        if validation_level == "flake":
            return self.validator.validate_flake_only()

        elif validation_level == "full":
            # Build only the machines that were updated
            machines_to_test = list(updated_machines.keys())
            results = self.validator.validate_machines(machines_to_test)

            # All machines must pass
            all_passed = all(results.values())
            if all_passed:
                print("✅ All validations passed!")
            else:
                failed = [m for m, success in results.items() if not success]
                print(f"❌ Validation failed for: {', '.join(failed)}")

            return all_passed

        else:
            print(f"Unknown validation level: {validation_level}")
            return False