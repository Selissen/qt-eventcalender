#!/usr/bin/env python3
"""
Builds the Flutter Windows app inside flutter/app/.

Usage:
    python scripts/build_flutter.py [--release | --debug]

Defaults to --release.  The build output lands at:
    flutter/app/build/windows/x64/runner/Release/   (release)
    flutter/app/build/windows/x64/runner/Debug/     (debug)

Run scripts/sync_flutter_artifacts.py afterwards to copy the artifacts
next to the Qt executable so the embedding can find them at runtime.
"""

import argparse
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FLUTTER_APP  = PROJECT_ROOT / "flutter" / "app"


def main():
    parser = argparse.ArgumentParser(description="Build the Flutter Windows app")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--release", action="store_true", default=True,
                       help="Release build (default)")
    group.add_argument("--debug",   action="store_false", dest="release",
                       help="Debug build (no AOT — aot_library_path not required)")
    args = parser.parse_args()

    if not FLUTTER_APP.exists():
        print("ERROR: flutter/app not found.  Run from the project root or check the monorepo.")
        sys.exit(1)

    mode = "release" if args.release else "debug"
    print(f"Building Flutter Windows app ({mode})…")

    # On Windows flutter is a .bat file, so shell=True is required.
    result = subprocess.run(
        f"flutter build windows --{mode}",
        cwd=FLUTTER_APP,
        shell=True,
    )

    if result.returncode != 0:
        print("\nFlutter build FAILED")
        sys.exit(result.returncode)

    runner_dir = FLUTTER_APP / "build" / "windows" / "x64" / "runner" / mode.capitalize()
    for name in ("app.exe", "flutter_windows.dll"):
        if not (runner_dir / name).exists():
            print(f"ERROR: Expected output missing: {runner_dir / name}")
            sys.exit(1)

    print(f"\nFlutter BUILD OK — output in:\n  {runner_dir}")
    return str(runner_dir)


if __name__ == "__main__":
    main()
