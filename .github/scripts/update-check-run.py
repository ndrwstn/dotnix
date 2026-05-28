#!/usr/bin/env python3
"""
update-check-run.py — Create or update a GitHub check run with hydra status.

Called from hydra-status-check.yml workflow.
Builds a proper JSON body and pipes it via gh api --input.

Usage:
    python3 .github/scripts/update-check-run.py <head_sha> <ready>
"""

import json
import os
import subprocess
import sys
import tempfile


def gh_api(method: str, endpoint: str, body: dict | None = None) -> dict | None:
    """Call gh api with a JSON body via --input.

    Raises SystemExit on HTTP or parse errors.
    """
    cmd = ["gh", "api", endpoint, "--method", method]
    input_path = None

    if body:
        fd, input_path = tempfile.mkstemp(suffix=".json", prefix="gh-payload-")
        with os.fdopen(fd, "w") as f:
            json.dump(body, f)
        cmd.extend(["--input", input_path])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    except subprocess.TimeoutExpired:
        print(f"Timeout calling {method} {endpoint}", file=sys.stderr)
        sys.exit(1)
    finally:
        if input_path and os.path.exists(input_path):
            os.unlink(input_path)

    if result.returncode != 0:
        print(
            f"gh api {method} {endpoint} failed (exit {result.returncode}):\n"
            f"  stderr: {result.stderr.strip()}",
            file=sys.stderr,
        )
        sys.exit(1)

    if result.stdout.strip():
        try:
            return json.loads(result.stdout.strip())
        except json.JSONDecodeError as e:
            print(
                f"Failed to parse response from {method} {endpoint}: {e}\n"
                f"  response: {result.stdout.strip()[:500]}",
                file=sys.stderr,
            )
            sys.exit(1)
    return None


def main():
    if len(sys.argv) < 3:
        print("Usage: update-check-run.py <head_sha> <ready>", file=sys.stderr)
        sys.exit(1)

    head_sha = sys.argv[1]
    ready = sys.argv[2].lower() == "true"

    # Read hydra results
    try:
        with open("/tmp/hydra-result.json") as f:
            result = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error reading hydra results: {e}", file=sys.stderr)
        sys.exit(1)

    owner = os.environ.get("GITHUB_REPOSITORY_OWNER", "")
    repo = (
        os.environ.get("GITHUB_REPOSITORY", "").split("/")[-1]
        if "/" in os.environ.get("GITHUB_REPOSITORY", "")
        else ""
    )
    if not owner or not repo:
        print("Missing GITHUB_REPOSITORY_OWNER or GITHUB_REPOSITORY", file=sys.stderr)
        sys.exit(1)

    summary = result.get("summary", "No summary available")

    # Build markdown details
    lines = ["## Hydra/Channel Readiness Check\n", "### Per-Input Results\n"]
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
    if result.get("ready"):
        lines.append(
            "✅ **Verdict: READY — all primary nixpkgs inputs at Hydra-ready revision**\n"
        )
    else:
        lines.append(
            "⏳ **Verdict: BUILDING — one or more nixpkgs inputs still building on Hydra**\n"
        )
    text = "\n".join(lines)

    conclusion = "success" if ready else "neutral"

    # Check if a check run already exists
    existing = gh_api("GET", f"/repos/{owner}/{repo}/commits/{head_sha}/check-runs")
    existing_id = None
    if existing:
        for run in existing.get("check_runs", []):
            if run.get("name") == "Hydra Status Check":
                existing_id = run.get("id")
                break

    # Build output sub-object
    output_object = {
        "title": summary[:72],  # GitHub caps title at ~72 chars
        "summary": summary,
        "text": text,
    }

    if existing_id:
        print(f"Updating check run {existing_id}")
        gh_api(
            "PATCH",
            f"/repos/{owner}/{repo}/check-runs/{existing_id}",
            {
                "status": "completed",
                "conclusion": conclusion,
                "output": output_object,
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
                "output": output_object,
            },
        )


if __name__ == "__main__":
    main()
