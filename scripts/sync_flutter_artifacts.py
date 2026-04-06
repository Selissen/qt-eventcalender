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
import os
import shutil
import sys
from pathlib import Path

PROJECT_ROOT  = Path(__file__).resolve().parent.parent
BUILD_ROOT    = PROJECT_ROOT / "build"
FLUTTER_APP   = PROJECT_ROOT / "flutter" / "app"
PREBUILT_APP  = PROJECT_ROOT / "prebuilt" / "flutter_app"
PREBUILT_ENG  = PROJECT_ROOT / "prebuilt" / "flutter_engine"


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


def _is_same(src: Path, dst: Path) -> bool:
    """Return True when dst exists and is no older than src (skip-if-unchanged)."""
    if not dst.exists():
        return False
    return dst.stat().st_mtime >= src.stat().st_mtime


def _copy_file(src: Path, dst: Path, label: str) -> bool:
    """Copy src → dst, skipping when unchanged. Returns True on success."""
    if _is_same(src, dst):
        print(f"  --  {label} (unchanged, skipped)")
        return True
    try:
        shutil.copy2(src, dst)
        print(f"  OK  {label}")
        return True
    except OSError as exc:
        # WinError 1224: file is memory-mapped by a running process.
        print(f"  !!  {label} — could not overwrite: {exc}")
        print(f"      Close the running application and re-run this script.")
        return False


def _sync_tree(src: Path, dst: Path, label: str) -> bool:
    """Sync a directory tree, skipping individual files that are unchanged."""
    if not src.exists():
        return True
    dst.mkdir(parents=True, exist_ok=True)
    any_failed = False
    for item in src.rglob("*"):
        if item.is_dir():
            continue
        rel = item.relative_to(src)
        dst_file = dst / rel
        dst_file.parent.mkdir(parents=True, exist_ok=True)
        if not _copy_file(item, dst_file, f"{label}/{rel}"):
            any_failed = True
    # Remove files in dst that no longer exist in src.
    for item in list(dst.rglob("*")):
        if item.is_dir():
            continue
        rel = item.relative_to(dst)
        if not (src / rel).exists():
            try:
                item.unlink()
            except OSError:
                pass
    return not any_failed


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

    use_prebuilt = False
    if not flutter_out.exists():
        if PREBUILT_APP.exists():
            print(f"Flutter build output not found; falling back to prebuilt artifacts.")
            use_prebuilt = True
        else:
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

    if use_prebuilt:
        print(f"Source : {PREBUILT_APP} (prebuilt)")
    else:
        print(f"Source : {flutter_out}")
    print(f"Dest   : {dest}")

    data_dir = PREBUILT_APP / "data" if use_prebuilt else flutter_out / "data"

    ok = True

    # flutter_assets/ — sync file-by-file so locked files are reported clearly.
    src_assets = data_dir / "flutter_assets"
    if src_assets.exists():
        if not _sync_tree(src_assets, dest / "flutter_assets", "flutter_assets"):
            ok = False

    # icudtl.dat
    src_icu = data_dir / "icudtl.dat"
    if src_icu.exists():
        if not _copy_file(src_icu, dest / "icudtl.dat", "icudtl.dat"):
            ok = False

    # app.so (release AOT snapshot)
    src_aot = data_dir / "app.so"
    if src_aot.exists():
        if not _copy_file(src_aot, dest / "app.so", "app.so"):
            ok = False
    elif args.release:
        print("  ! app.so not found — AOT snapshot missing, embedding may fail")

    # flutter_windows.dll
    src_dll = (PREBUILT_ENG / "flutter_windows.dll"
               if use_prebuilt else flutter_out / "flutter_windows.dll")
    if src_dll.exists():
        if not _copy_file(src_dll, dest / "flutter_windows.dll", "flutter_windows.dll"):
            ok = False

    if ok:
        print("\nSync complete.")
    else:
        print("\nSync finished with errors (see above).")
        sys.exit(1)


if __name__ == "__main__":
    main()
