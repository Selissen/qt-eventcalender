#!/usr/bin/env python3
"""
One-command WASM build + test.

    python scripts/check_wasm.py

Equivalent to:
    python scripts/build_wasm.py && python scripts/test_wasm.py

Exits 0 on success, non-zero on any build or runtime failure.
"""

import subprocess
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent


def run(script: str, extra_args: list[str] = ()) -> int:
    result = subprocess.run(
        [sys.executable, str(SCRIPTS / script), *extra_args]
    )
    return result.returncode


def main():
    print("=" * 60)
    print("Step 1/2 — Build")
    print("=" * 60)
    if run("build_wasm.py", sys.argv[1:]) != 0:
        sys.exit(1)

    print()
    print("=" * 60)
    print("Step 2/2 — Test")
    print("=" * 60)
    sys.exit(run("test_wasm.py"))


if __name__ == "__main__":
    main()
