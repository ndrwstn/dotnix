"""
Configuration file parsing utilities for Nix machine configurations.
"""

import re
from pathlib import Path
from typing import Dict, List, Optional


class NixConfigParser:
    """Parser for Nix configuration files."""

    @staticmethod
    def extract_permitted_insecure_packages(content: str) -> List[str]:
        """Extract permittedInsecurePackages from Nix configuration content."""
        # Find the permittedInsecurePackages list
        match = re.search(
            r'permittedInsecurePackages\s*=\s*\[(.*?)\];',
            content,
            re.DOTALL
        )

        if not match:
            return []

        # Extract quoted strings from the list
        packages_text = match.group(1)
        packages = re.findall(r'"([^"]*)"', packages_text)

        return packages

    @staticmethod
    def update_permitted_insecure_packages(content: str, packages: List[str]) -> str:
        """Update permittedInsecurePackages in Nix configuration content."""
        # Find the existing permittedInsecurePackages block
        pattern = r'(permittedInsecurePackages\s*=\s*\[)(.*?)(\];)'

        # Format the new packages list
        if packages:
            indented_packages = '\n'.join(f'    "{pkg}"' for pkg in packages)
            new_list_content = f'\n{indented_packages}\n  '
        else:
            new_list_content = '\n  '

        # Replace the content
        new_content = re.sub(
            pattern,
            r'\1' + new_list_content + r'\3',
            content,
            flags=re.DOTALL
        )

        return new_content

    @staticmethod
    def has_permitted_insecure_packages(content: str) -> bool:
        """Check if a configuration file has permittedInsecurePackages."""
        return 'permittedInsecurePackages' in content


class MachineConfigManager:
    """Manages machine configuration files."""

    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.machines_dir = repo_root / "machines"

    def discover_machines(self) -> List[str]:
        """Discover all valid machine directories."""
        machines = []
        if not self.machines_dir.exists():
            return machines

        for item in self.machines_dir.iterdir():
            if item.is_dir() and (item / "configuration.nix").exists():
                machines.append(item.name)

        return sorted(machines)

    def get_machine_config(self, machine: str) -> Optional[str]:
        """Get the content of a machine configuration file."""
        config_file = self.machines_dir / machine / "configuration.nix"
        if config_file.exists():
            return config_file.read_text()
        return None

    def update_machine_config(self, machine: str, content: str) -> bool:
        """Update a machine configuration file."""
        config_file = self.machines_dir / machine / "configuration.nix"
        try:
            config_file.write_text(content)
            return True
        except Exception as e:
            print(f"Error writing {config_file}: {e}")
            return False

    def get_machines_with_insecure_packages(self) -> Dict[str, List[str]]:
        """Find all machines that have permittedInsecurePackages."""
        machines_with_insecure = {}

        for machine in self.discover_machines():
            content = self.get_machine_config(machine)
            if content and NixConfigParser.has_permitted_insecure_packages(content):
                packages = NixConfigParser.extract_permitted_insecure_packages(content)
                if packages:
                    machines_with_insecure[machine] = packages

        return machines_with_insecure

    def update_machine_insecure_packages(self, machine: str, packages: List[str]) -> bool:
        """Update permittedInsecurePackages for a specific machine."""
        content = self.get_machine_config(machine)
        if not content:
            return False

        updated_content = NixConfigParser.update_permitted_insecure_packages(content, packages)

        return self.update_machine_config(machine, updated_content)