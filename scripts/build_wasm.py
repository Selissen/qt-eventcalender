#!/usr/bin/env python3
"""
Rebuilds the WebAssembly target using the Qt Creator-managed build directory.

Usage:
    python scripts/build_wasm.py [--release | --debug]

The script finds the most recently configured WASM build directory under
build/ automatically, so no paths need to be hardcoded.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
BUILD_ROOT   = PROJECT_ROOT / "build"


def find_wasm_build_dirs():
    if not BUILD_ROOT.exists():
        return []
    return sorted(
        [d for d in BUILD_ROOT.iterdir()
         if d.is_dir() and d.name.lower().startswith("webassembly")
         and (d / "CMakeCache.txt").exists()],
        key=lambda d: d.stat().st_mtime,
        reverse=True,
    )


def main():
    parser = argparse.ArgumentParser(description="Build the WASM target")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--release", action="store_true", help="Prefer RelWithDebInfo build")
    group.add_argument("--debug",   action="store_true", help="Prefer Debug build")
    args = parser.parse_args()

    dirs = find_wasm_build_dirs()
    if not dirs:
        print("ERROR: No WebAssembly build directory found under build/.")
        print("Configure the project with the Qt WASM kit in Qt Creator first.")
        sys.exit(1)

    # Prefer release/debug match if requested, otherwise use the most recent.
    build_dir = dirs[0]
    if args.release:
        preferred = [d for d in dirs if "relwithdebinfo" in d.name.lower() or "release" in d.name.lower()]
        if preferred:
            build_dir = preferred[0]
    elif args.debug:
        preferred = [d for d in dirs if "debug" in d.name.lower()]
        if preferred:
            build_dir = preferred[0]

    print(f"Building: {build_dir.name}")

    result = subprocess.run(
        ["cmake", "--build", str(build_dir), "--parallel"],
        cwd=PROJECT_ROOT,
    )

    if result.returncode != 0:
        print("\nBUILD FAILED")
        sys.exit(result.returncode)

    # Verify expected outputs exist.
    for name in ("eventcalendar.html", "eventcalendar.js", "eventcalendar.wasm"):
        if not (build_dir / name).exists():
            print(f"ERROR: Expected output missing: {name}")
            sys.exit(1)

    print(f"\nBUILD OK — output in:\n  {build_dir}")
    return str(build_dir)


if __name__ == "__main__":
    main()
