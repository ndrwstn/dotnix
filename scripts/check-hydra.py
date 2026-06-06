#!/usr/bin/env python3
"""
check-hydra.py — Check if pinned nixpkgs revisions have been built by hydra.

Queries hydra.nixos.org's public JSON API (NOT blocked by Anubis), plus
channels.nixos.org and the GitHub compare API, to determine whether
the nixpkgs revisions pinned in flake.lock are fully built and cached.

Output: JSON to stdout with per-input status and an overall "ready" verdict.
Exit code: 0 on success (ready or building), 1 on error.

Usage:
    python3 scripts/check-hydra.py [/path/to/flake.lock]
"""

import json
import os
import subprocess
import sys


# ── Mapping: flake input → hydra jobset + channel ──────────────────────────
INPUT_MAP = {
    "nixpkgs": {
        "channel": "nixos-26.05",
        "jobset": "release-26.05",
    },
    "nixpkgs-unstable": {
        "channel": "nixos-unstable",
        "jobset": "unstable",
    },
    "nixpkgs-darwin": {
        "channel": "nixpkgs-26.05-darwin",
        "jobset": "nixpkgs-26.05-darwin",
    },
}


# ── Helpers ────────────────────────────────────────────────────────────────


def curl(url: str, timeout: int = 30) -> str:
    """Fetch a URL using curl (more portable across network environments)."""
    try:
        result = subprocess.run(
            [
                "curl",
                "-sL",
                "--max-time",
                str(timeout),
                "-H",
                "Accept: application/json"
                if "api.github" in url or "hydra" in url
                else "",
                url,
            ],
            capture_output=True,
            text=True,
            timeout=timeout + 5,
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def curl_text(url: str, timeout: int = 15) -> str:
    """Fetch plain text via curl."""
    try:
        result = subprocess.run(
            ["curl", "-sL", "--max-time", str(timeout), url],
            capture_output=True,
            text=True,
            timeout=timeout + 5,
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def curl_json(url: str, timeout: int = 20):
    """Fetch and parse JSON via curl."""
    text = curl(url, timeout)
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return None


# ── Check phases ───────────────────────────────────────────────────────────


def check_channel_rev(pinned_rev: str, channel: str) -> tuple[str | None, str | None]:
    """Phase 1: compare pinned rev to current channel git-revision.

    Returns (status, channel_rev) where status is 'built' or None.
    """
    channel_rev = curl_text(f"https://channels.nixos.org/{channel}/git-revision")
    if not channel_rev:
        return None, None
    if pinned_rev == channel_rev:
        return "built", channel_rev
    return None, channel_rev


def check_hydra_eval(pinned_rev: str, jobset: str) -> str | None:
    """Phase 2: query hydra's latest nixpkgs.tarball build for this jobset.

    Extracts the nixpkgs revision from the build's nixname
    (format: nixpkgs-tarball-{channel}pre{N}.{REVISION}) and compares.
    """
    url = (
        f"https://hydra.nixos.org/api/latestbuilds"
        f"?nr=1&project=nixos&jobset={jobset}&job=nixpkgs.tarball"
    )
    data = curl_json(url, timeout=20)
    if not data or not isinstance(data, list) or len(data) == 0:
        return None

    build = data[0]
    if not isinstance(build, dict):
        return None

    # Check nixname for embedded revision
    nixname = build.get("nixname", "")
    if "." in nixname:
        hydra_rev = nixname.rsplit(".", 1)[-1]
        if pinned_rev.startswith(hydra_rev):
            return "built"

    # Also check eval-level nixpkgs revision
    evals = build.get("jobsetevals", [])
    if evals:
        eval_data = curl_json(f"https://hydra.nixos.org/eval/{evals[0]}", timeout=15)
        if isinstance(eval_data, dict):
            for inp in eval_data.get("jobsetevalinputs", {}).values():
                rev = ""
                if isinstance(inp, dict):
                    rev = inp.get("revision", "")
                if rev and pinned_rev.startswith(rev):
                    return "built"

    return None


def check_ancestry(pinned_rev: str, channel_rev: str) -> str | None:
    """Phase 3: use GitHub compare API to check if pinned rev is an ancestor
    of the current channel revision.

    For compare/{base}...{head}, when {base} (pinned) is behind {head}
    (channel), the pinned rev is an ancestor — confirmed built.

    Returns 'built' if behind/identical, None otherwise.
    """
    if not channel_rev:
        return None

    url = (
        f"https://api.github.com/repos/NixOS/nixpkgs/"
        f"compare/{pinned_rev}...{channel_rev}"
    )
    data = curl_json(url, timeout=15)
    if not isinstance(data, dict):
        return None

    status = data.get("status", "")
    if status in ("behind", "identical"):
        return "built"
    return None


def check_prometheus_health(channel: str) -> bool | None:
    """Check if the NixOS channel's 'tested' job is passing via prometheus."""
    url = (
        f"https://prometheus.nixos.org/api/v1/query"
        f"?query=hydra_job_failed%7Bchannel%3D%22{channel}%22%7D"
    )
    data = curl_json(url, timeout=15)
    if not isinstance(data, dict):
        return False
    try:
        results = data.get("data", {}).get("result", [])
        for r in results:
            if isinstance(r, dict):
                exported = r.get("metric", {}).get("exported_job", "")
                if exported == "tested":
                    return r.get("value", [None, "1"])[1] == "0"
        if results and isinstance(results[0], dict):
            return results[0].get("value", [None, "1"])[1] == "0"
    except (KeyError, IndexError, TypeError):
        pass
    return False


# ── Main ───────────────────────────────────────────────────────────────────


def main():
    lock_path = sys.argv[1] if len(sys.argv) > 1 else "flake.lock"
    if not os.path.exists(lock_path):
        output = {"error": f"File not found: {lock_path}"}
        print(json.dumps(output))
        sys.exit(1)

    with open(lock_path) as f:
        lock = json.load(f)

    nodes = lock.get("nodes", {})
    root_node = nodes.get("root", {})
    root_inputs = root_node.get("inputs", {}) if isinstance(root_node, dict) else {}

    # Resolve the actual node key for each input by following root inputs.
    # flake.lock may have multiple nixpkgs* entries (e.g. nixpkgs_2) due to
    # transitive dependencies; we must use the root's input reference, not a
    # direct key lookup.
    def resolve_node_key(name: str) -> str | None:
        """Return the node key the root input points to, or None if unresolvable."""
        key = root_inputs.get(name)
        if key and key in nodes:
            return key
        # Fallback: direct key lookup (older lock format without dedup)
        if name in nodes:
            return name
        return None

    input_nodes = {}
    for name in INPUT_MAP:
        node_key = resolve_node_key(name)
        if node_key:
            input_nodes[name] = node_key

    inputs_missing = [name for name in INPUT_MAP if name not in input_nodes]

    # Treat any missing required input as unready
    if inputs_missing:
        results = []
        all_built = False
        for name in INPUT_MAP:
            node_key = input_nodes.get(name)
            if node_key:
                node = nodes.get(node_key, {})
                locked = node.get("locked", {}) if isinstance(node, dict) else {}
                pinned_rev = locked.get("rev", "")
                results.append(
                    {
                        "name": name,
                        "rev": pinned_rev,
                        "channel": INPUT_MAP[name]["channel"],
                        "jobset": INPUT_MAP[name]["jobset"],
                        "status": "built" if pinned_rev else "error",
                        "detail": "Missing required co-inputs — overall result is unready",
                        "channel_healthy": False,
                    }
                )
            else:
                results.append(
                    {
                        "name": name,
                        "rev": "",
                        "channel": INPUT_MAP[name]["channel"],
                        "jobset": INPUT_MAP[name]["jobset"],
                        "status": "missing",
                        "detail": "Required input not found in flake.lock",
                        "channel_healthy": False,
                    }
                )
        output = {
            "ready": False,
            "inputs": results,
            "summary": "One or more required nixpkgs inputs missing from flake.lock",
        }
        print(json.dumps(output, indent=2))
        sys.exit(0)

    results = []
    all_built = True

    for name in INPUT_MAP:
        node_key = input_nodes[name]
        node = nodes.get(node_key, {})
        locked = node.get("locked", {}) if isinstance(node, dict) else {}
        pinned_rev = locked.get("rev", "")

        if not pinned_rev:
            results.append(
                {
                    "name": name,
                    "rev": "",
                    "channel": INPUT_MAP[name]["channel"],
                    "jobset": INPUT_MAP[name]["jobset"],
                    "status": "error",
                    "detail": "No rev in flake.lock",
                    "channel_healthy": False,
                }
            )
            all_built = False
            continue

        info = {
            "name": name,
            "rev": pinned_rev,
            "channel": INPUT_MAP[name]["channel"],
            "jobset": INPUT_MAP[name]["jobset"],
            "status": "unknown",
            "detail": "",
            "channel_healthy": False,
        }

        # Phase 1: Channel match (cheapest, fastest)
        result, channel_rev = check_channel_rev(pinned_rev, info["channel"])
        if result:
            info["status"] = "built"
            info["detail"] = "Pinned revision matches current channel git-revision"
        else:
            # Phase 2: Hydra latest eval match
            result = check_hydra_eval(pinned_rev, info["jobset"])
            if result:
                info["status"] = "built"
                info["detail"] = "Pinned revision matches latest hydra eval"

        # Phase 3: GitHub ancestry check (only if we have channel_rev)
        if info["status"] != "built":
            if not channel_rev:
                channel_rev = curl_text(
                    f"https://channels.nixos.org/{info['channel']}/git-revision",
                )
            if channel_rev:
                result = check_ancestry(pinned_rev, channel_rev)
                if result:
                    info["status"] = "built"
                    info["detail"] = "Pinned revision is ancestor of current channel"

        # Phase 4: Channel health (informational)
        healthy = check_prometheus_health(info["channel"])
        info["channel_healthy"] = healthy if healthy is not None else False

        if info["status"] != "built":
            info["status"] = "building"
            info["detail"] = (
                "Revision still building on Hydra — "
                "not found in channel, hydra latest eval, or ancestry chain"
            )
            all_built = False
        elif info.get("channel_healthy"):
            info["detail"] += "; channel tested job is passing"

        results.append(info)

    # Overall verdict
    ready = all_built

    output = {
        "ready": ready,
        "inputs": results,
        "summary": (
            "All primary nixpkgs inputs at Hydra-ready revision"
            if ready
            else "One or more nixpkgs inputs still building on Hydra"
        ),
    }

    print(json.dumps(output, indent=2))

    sys.exit(0)


if __name__ == "__main__":
    main()
