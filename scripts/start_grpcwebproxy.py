#!/usr/bin/env python3
"""
Downloads (once) and starts grpcwebproxy for WASM gRPC-Web testing.

grpcwebproxy sits between the browser (WASM) and the local gRPC server,
translating gRPC-Web requests into native gRPC.

Usage:
    python scripts/start_grpcwebproxy.py [--backend localhost:50051] [--port 8080]

The binary is cached in scripts/bin/ after the first download.
No other dependencies required — uses only the Python standard library.

Typical workflow (two terminals):
    terminal 1:  python scripts/test_server.py
    terminal 2:  python scripts/start_grpcwebproxy.py
    browser:     python scripts/serve_wasm.py    (WASM app talks to :8080)
"""

import argparse
import json
import os
import platform
import stat
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
BIN_DIR    = SCRIPT_DIR / "bin"
GITHUB_REPO = "improbable-eng/grpc-web"


# ── Platform detection ────────────────────────────────────────────────────────

def _platform_tokens() -> tuple[str, str, str]:
    """Return (os_token, arch_token, exe_suffix) for the current machine."""
    if sys.platform == "win32":
        os_tok = "windows"
        suffix = ".exe"
    elif sys.platform == "darwin":
        os_tok = "osx"
        suffix = ""
    else:
        os_tok = "linux"
        suffix = ""

    machine = platform.machine().lower()
    arch_tok = "x86_64" if machine in ("x86_64", "amd64") else "arm64"
    return os_tok, arch_tok, suffix


# ── Binary acquisition ────────────────────────────────────────────────────────

def _find_cached() -> Path | None:
    if BIN_DIR.exists():
        for p in BIN_DIR.iterdir():
            if p.stem.startswith("grpcwebproxy"):
                return p
    return None


def _fetch_latest_release() -> dict:
    url = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
    req = urllib.request.Request(url, headers={"User-Agent": "eventcalendar-dev"})
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read())


def _download_binary() -> Path:
    BIN_DIR.mkdir(exist_ok=True)
    os_tok, arch_tok, suffix = _platform_tokens()

    print("[grpcwebproxy] Fetching latest release info from GitHub...")
    release = _fetch_latest_release()
    version = release["tag_name"]
    print(f"[grpcwebproxy] Latest release: {version}")

    # Find the asset whose name contains both the os and arch tokens
    asset = next(
        (
            a for a in release["assets"]
            if "grpcwebproxy" in a["name"].lower()
            and os_tok in a["name"].lower()
            and arch_tok in a["name"].lower()
        ),
        None,
    )
    if asset is None:
        available = [a["name"] for a in release["assets"]]
        sys.exit(
            f"No binary found for {os_tok}/{arch_tok}.\n"
            f"Available assets: {available}"
        )

    print(f"[grpcwebproxy] Downloading {asset['name']}...")
    download_path = BIN_DIR / asset["name"]
    urllib.request.urlretrieve(asset["browser_download_url"], download_path)

    # Extract from zip if needed
    if asset["name"].endswith(".zip"):
        with zipfile.ZipFile(download_path) as z:
            members = [m for m in z.namelist() if "grpcwebproxy" in m.lower()]
            if not members:
                sys.exit("Could not find grpcwebproxy binary inside the zip archive.")
            member = members[0]
            dest_name = Path(member).name
            dest = BIN_DIR / dest_name
            dest.write_bytes(z.read(member))
        download_path.unlink()
        download_path = dest

    # Ensure executable bit on Unix
    if sys.platform != "win32":
        download_path.chmod(download_path.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP)

    print(f"[grpcwebproxy] Saved to {download_path}")
    return download_path


def find_or_download() -> Path:
    cached = _find_cached()
    if cached:
        print(f"[grpcwebproxy] Using cached binary: {cached.name}")
        return cached
    return _download_binary()


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Start grpcwebproxy to bridge WASM gRPC-Web → native gRPC"
    )
    parser.add_argument(
        "--backend", default="localhost:50051",
        help="Native gRPC backend address (default: localhost:50051)",
    )
    parser.add_argument(
        "--port", type=int, default=8080,
        help="HTTP port for gRPC-Web clients (default: 8080)",
    )
    args = parser.parse_args()

    binary = find_or_download()

    cmd = [
        str(binary),
        f"--backend_addr={args.backend}",
        f"--server_http_debug_port={args.port}",
        "--run_tls_server=false",
        "--allow_all_origins",
        # Long timeouts keep the SubscribePlans stream alive indefinitely
        "--server_http_max_read_timeout=24h",
        "--server_http_max_write_timeout=24h",
    ]

    print(f"[grpcwebproxy] Proxy   : http://localhost:{args.port}  (gRPC-Web)")
    print(f"[grpcwebproxy] Backend : {args.backend}  (native gRPC)")
    print("[grpcwebproxy] Set WASM server URL to"
          f" http://localhost:{args.port} in eventcalendar.cpp")
    print("[grpcwebproxy] Press Ctrl+C to stop\n")

    try:
        subprocess.run(cmd, check=False)
    except FileNotFoundError:
        sys.exit(f"Binary not executable: {binary}")
    except KeyboardInterrupt:
        print("\n[grpcwebproxy] Stopped")


if __name__ == "__main__":
    main()
