#!/usr/bin/env python3
"""
Copies Flutter build artifacts next to the Qt desktop executable so the
FlutterContainer can find them at runtime.

Usage:
    python scripts/sync_flutter_artifacts.py [--release | --debug]

Artifacts copied:
    flutter_assets/   — Dart assets bundle
    icudtl.dat        — ICU data
    app.so            — AOT snapshot (release only; skipped for debug)
    flutter_windows.dll — Flutter engine DLL

The destination is the most recently modified Desktop Qt build directory
under build/.  Pass --build-dir to override.
"""

import argparse
import shutil
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
BUILD_ROOT   = PROJECT_ROOT / "build"
FLUTTER_APP  = PROJECT_ROOT / "flutter" / "app"


def find_desktop_build_dirs():
    if not BUILD_ROOT.exists():
        return []
    return sorted(
        [d for d in BUILD_ROOT.iterdir()
         if d.is_dir() and d.name.lower().startswith("desktop")
         and (d / "CMakeCache.txt").exists()],
        key=lambda d: d.stat().st_mtime,
        reverse=True,
    )


def main():
    parser = argparse.ArgumentParser(description="Sync Flutter artifacts to the Qt build dir")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--release", action="store_true", default=True,
                       help="Sync from release build (default)")
    group.add_argument("--debug",   action="store_false", dest="release",
                       help="Sync from debug build")
    parser.add_argument("--build-dir", metavar="PATH",
                        help="Override destination Qt build directory")
    args = parser.parse_args()

    mode = "Release" if args.release else "Debug"
    flutter_out = FLUTTER_APP / "build" / "windows" / "x64" / "runner" / mode

    if not flutter_out.exists():
        print(f"ERROR: Flutter build output not found: {flutter_out}")
        print(f"Run:  python scripts/build_flutter.py --{'release' if args.release else 'debug'}")
        sys.exit(1)

    if args.build_dir:
        dest = Path(args.build_dir)
    else:
        dirs = find_desktop_build_dirs()
        if not dirs:
            print("ERROR: No Desktop Qt build directory found under build/.")
            print("Build the project with the MinGW kit in Qt Creator first.")
            sys.exit(1)
        dest = dirs[0]

    print(f"Source : {flutter_out}")
    print(f"Dest   : {dest}")

    data_dir = flutter_out / "data"

    # flutter_assets/
    src_assets = data_dir / "flutter_assets"
    if src_assets.exists():
        dst_assets = dest / "flutter_assets"
        if dst_assets.exists():
            shutil.rmtree(dst_assets)
        shutil.copytree(src_assets, dst_assets)
        print("  OK  flutter_assets/")

    # icudtl.dat
    src_icu = data_dir / "icudtl.dat"
    if src_icu.exists():
        shutil.copy2(src_icu, dest / "icudtl.dat")
        print("  OK  icudtl.dat")

    # app.so (release AOT snapshot)
    src_aot = data_dir / "app.so"
    if src_aot.exists():
        shutil.copy2(src_aot, dest / "app.so")
        print("  OK  app.so")
    elif args.release:
        print("  ! app.so not found — AOT snapshot missing, embedding may fail")

    # flutter_windows.dll
    src_dll = flutter_out / "flutter_windows.dll"
    if src_dll.exists():
        shutil.copy2(src_dll, dest / "flutter_windows.dll")
        print("  OK  flutter_windows.dll")

    print("\nSync complete.")


if __name__ == "__main__":
    main()
