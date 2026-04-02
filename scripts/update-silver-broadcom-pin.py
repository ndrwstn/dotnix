#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = REPO_ROOT / "machines" / "silver" / "configuration.nix"
EVAL_TARGET = (
    ".#nixosConfigurations.silver.config.boot.kernelPackages.broadcom_sta.name"
)
PACKAGE_PATTERN = re.compile(r'"(broadcom-sta-[^"]+)"')


def run_command(command: list[str]) -> str:
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
        raise SystemExit(result.returncode)

    return result.stdout.strip()


def evaluate_broadcom_package_name() -> str:
    package_name = run_command(["nix", "eval", "--raw", EVAL_TARGET])

    if not package_name.startswith("broadcom-sta-"):
        raise SystemExit(f"Expected a broadcom-sta package name, got: {package_name!r}")

    return package_name


def replace_pin(new_package_name: str) -> tuple[str, bool]:
    content = CONFIG_PATH.read_text()
    matches = PACKAGE_PATTERN.findall(content)

    if len(matches) != 1:
        raise SystemExit(
            "Expected exactly one quoted broadcom-sta package string in "
            f"{CONFIG_PATH}, found {len(matches)}"
        )

    current_package_name = matches[0]

    if current_package_name == new_package_name:
        print(f"Silver Broadcom pin already up to date: {current_package_name}")
        return current_package_name, False

    updated_content, replacements = PACKAGE_PATTERN.subn(
        f'"{new_package_name}"',
        content,
        count=1,
    )

    if replacements != 1:
        raise SystemExit(
            f"Expected exactly one replacement in {CONFIG_PATH}, got {replacements}"
        )

    CONFIG_PATH.write_text(updated_content)
    print(f"Updated Silver Broadcom pin: {current_package_name} -> {new_package_name}")
    return current_package_name, True


def main() -> int:
    evaluated_package_name = evaluate_broadcom_package_name()
    _, changed = replace_pin(evaluated_package_name)

    print(f"::notice::silver_broadcom_changed={str(changed).lower()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
