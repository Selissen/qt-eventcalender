#!/usr/bin/env python3
"""
One-command Flutter build + artifact sync.

    python scripts/check_flutter.py

Equivalent to:
    python scripts/build_flutter.py && python scripts/sync_flutter_artifacts.py

Exits 0 on success, non-zero on any failure.
"""

import subprocess
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent


def run(script: str, extra_args: list[str] = ()) -> int:
    result = subprocess.run(
        [sys.executable, str(SCRIPTS / script), *extra_args],
    )
    return result.returncode


def main():
    if run("build_flutter.py") != 0:
        sys.exit(1)
    if run("sync_flutter_artifacts.py") != 0:
        sys.exit(1)
    print("\ncheck_flutter: all steps passed.")


if __name__ == "__main__":
    main()
