"""
Nix-specific helper utilities for the insecure package updater.
"""

import subprocess
import json
from typing import Dict, List, Optional


def run_nix_command(cmd: List[str], cwd: Optional[str] = None, timeout: int = 30) -> subprocess.CompletedProcess:
    """Run a nix command with proper error handling."""
    try:
        return subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=True
        )
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Nix command failed: {' '.join(cmd)}\n{e.stderr}")
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"Nix command timed out: {' '.join(cmd)}")


def get_flake_lock_info(flake_path: str = ".") -> Dict:
    """Get information about the current flake.lock."""
    try:
        result = run_nix_command(["nix", "flake", "metadata", "--json"], cwd=flake_path)
        return json.loads(result.stdout)
    except Exception:
        return {}


def update_flake_lock(flake_path: str = ".") -> bool:
    """Update the flake.lock file."""
    try:
        run_nix_command(["nix", "flake", "update"], cwd=flake_path, timeout=300)
        return True
    except Exception as e:
        print(f"Warning: Failed to update flake.lock: {e}")
        return False


def check_flake(flake_path: str = ".") -> bool:
    """Run nix flake check."""
    try:
        run_nix_command(["nix", "flake", "check"], cwd=flake_path, timeout=300)
        return True
    except Exception as e:
        print(f"Flake check failed: {e}")
        return False


def get_nixpkgs_packages() -> List[str]:
    """Get a list of all packages in nixpkgs (for discovery)."""
    try:
        # This is a simplified approach - in practice you might want to cache this
        result = run_nix_command([
            "nix", "search", "nixpkgs", "--json", "--exclude", "*.*"
        ], timeout=60)

        data = json.loads(result.stdout)
        return list(data.keys())
    except Exception:
        return []


def get_package_attribute_path(package_name: str) -> Optional[str]:
    """Find the attribute path for a package in nixpkgs."""
    try:
        result = run_nix_command([
            "nix", "search", "nixpkgs", package_name, "--json"
        ], timeout=30)

        data = json.loads(result.stdout)
        if data:
            # Return the first matching attribute path
            return list(data.keys())[0]
        return None
    except Exception:
        return None