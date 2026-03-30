#!/usr/bin/env python3
"""
Serves the WASM build locally with the COOP/COEP headers Qt threading requires.
Opens the app in your default browser automatically.

Usage:
    python scripts/serve_wasm.py [--port 8080]

Press Ctrl+C to stop.
"""

import argparse
import http.server
import os
import sys
import webbrowser
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
BUILD_ROOT   = PROJECT_ROOT / "build"


class CoopCoepHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy",   "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()


def find_wasm_build_dir():
    if not BUILD_ROOT.exists():
        return None
    dirs = sorted(
        [d for d in BUILD_ROOT.iterdir()
         if d.is_dir() and d.name.lower().startswith("webassembly")
         and (d / "eventcalendar.html").exists()],
        key=lambda d: d.stat().st_mtime,
        reverse=True,
    )
    return dirs[0] if dirs else None


def main():
    parser = argparse.ArgumentParser(description="Serve WASM build locally")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--build-dir", help="Path to WASM build output directory")
    args = parser.parse_args()

    build_dir = Path(args.build_dir) if args.build_dir else find_wasm_build_dir()
    if not build_dir or not (build_dir / "eventcalendar.html").exists():
        print("ERROR: WASM build output not found.")
        print("Run 'python scripts/build_wasm.py' first.")
        sys.exit(1)

    os.chdir(build_dir)
    url = f"http://localhost:{args.port}/eventcalendar.html"
    print(f"Serving:  {build_dir.name}")
    print(f"URL:      {url}")
    print("Press Ctrl+C to stop.\n")
    webbrowser.open(url)

    try:
        http.server.test(HandlerClass=CoopCoepHandler, port=args.port, bind="localhost")
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
