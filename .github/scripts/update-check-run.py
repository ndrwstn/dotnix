#!/usr/bin/env python3
"""
update-check-run.py — Create or update a GitHub check run with hydra status.

Called from hydra-status-check.yml workflow.

Usage:
    python3 .github/scripts/update-check-run.py <head_sha> <warm>
"""

import json
import os
import subprocess
import sys


def gh_api(method: str, endpoint: str, fields: dict | None = None) -> dict | None:
    """Call gh api and return parsed JSON."""
    cmd = ["gh", "api", endpoint, "--method", method]
    if fields:
        for key, value in fields.items():
            if isinstance(value, dict | list):
                cmd.extend(["--field", f"{key}={json.dumps(value)}"])
            else:
                cmd.extend(["--field", f"{key}={value}"])
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout.strip())
    except (subprocess.TimeoutExpired, json.JSONDecodeError):
        pass
    return None


def main():
    if len(sys.argv) < 3:
        print("Usage: update-check-run.py <head_sha> <warm>", file=sys.stderr)
        sys.exit(1)

    head_sha = sys.argv[1]
    warm = sys.argv[2].lower() == "true"

    # Read hydra results
    try:
        with open("/tmp/hydra-result.json") as f:
            result = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        result = {
            "warm": False,
            "summary": "Error reading hydra check results",
            "inputs": [],
        }

    owner = os.environ.get("GITHUB_REPOSITORY_OWNER", "")
    repo = (
        os.environ.get("GITHUB_REPOSITORY", "").split("/")[-1]
        if "/" in os.environ.get("GITHUB_REPOSITORY", "")
        else ""
    )

    summary = result.get("summary", "No summary available")

    # Build markdown details
    lines = ["## Hydra Status Check\n", "### Per-Input Results\n"]
    lines.append("| Input | Revision | Channel | Status |")
    lines.append("|-------|----------|---------|--------|")
    for inp in result.get("inputs", []):
        rev_short = (inp.get("rev", "?")[:12] + "...") if inp.get("rev") else "?"
        lines.append(
            f"| {inp['name']} | {rev_short} | {inp['channel']} | {inp['status']} |"
        )
    lines.append("\n### Details\n")
    for inp in result.get("inputs", []):
        lines.append(f"**{inp['name']}**: {inp.get('detail', 'N/A')}\n")
    if result.get("warm"):
        lines.append("✅ **Verdict: WARM — all dependencies built by hydra**\n")
    else:
        lines.append("⏳ **Verdict: COLD — one or more dependencies not yet built**\n")
    text = "\n".join(lines)

    conclusion = "success" if warm else "neutral"

    # Check if a check run already exists
    existing = gh_api("GET", f"/repos/{owner}/{repo}/commits/{head_sha}/check-runs")
    existing_id = None
    if existing:
        for run in existing.get("check_runs", []):
            if run.get("name") == "Hydra Status Check":
                existing_id = run.get("id")
                break

    output_payload = json.dumps(
        {
            "title": summary,
            "summary": summary,
            "text": text,
        }
    )

    if existing_id:
        print(f"Updating check run {existing_id}")
        gh_api(
            "PATCH",
            f"/repos/{owner}/{repo}/check-runs/{existing_id}",
            {
                "status": "completed",
                "conclusion": conclusion,
                "output": output_payload,
            },
        )
    else:
        print(f"Creating check run for {head_sha[:12]}...")
        gh_api(
            "POST",
            f"/repos/{owner}/{repo}/check-runs",
            {
                "name": "Hydra Status Check",
                "head_sha": head_sha,
                "status": "completed",
                "conclusion": conclusion,
                "output": output_payload,
            },
        )


if __name__ == "__main__":
    main()
