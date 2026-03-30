#!/usr/bin/env python3
"""
Headless browser test for the WASM build.

Starts a local HTTP server with the required COOP/COEP headers, loads the
app in headless Chromium via Playwright, and reports any QML/JS errors found
in the browser console.

Usage:
    python scripts/test_wasm.py [--build-dir path/to/wasm/build] [--timeout 30]

First run will install Playwright and download Chromium automatically.
"""

import argparse
import io
import sys
# Ensure UTF-8 output on Windows consoles that default to cp1252.
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
import http.server
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
BUILD_ROOT   = PROJECT_ROOT / "build"
PORT         = 18765   # unlikely to conflict with anything


# ── COOP/COEP HTTP server ──────────────────────────────────────────────────────

class CoopCoepHandler(http.server.SimpleHTTPRequestHandler):
    """Adds Cross-Origin isolation headers required for Qt WASM threading."""

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy",   "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, *_):
        pass  # silence per-request logs


def start_server(directory: str) -> http.server.HTTPServer:
    os.chdir(directory)
    server = http.server.HTTPServer(("localhost", PORT), CoopCoepHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


# ── Playwright bootstrap ───────────────────────────────────────────────────────

def ensure_playwright():
    """Install playwright + chromium if not already present."""
    try:
        import playwright  # noqa: F401
    except ModuleNotFoundError:
        print("Installing Playwright (first run only)...")
        subprocess.run([sys.executable, "-m", "pip", "install", "playwright"],
                       check=True)
        print("Downloading Chromium...")
        subprocess.run([sys.executable, "-m", "playwright", "install", "chromium"],
                       check=True)


# ── Error classification ───────────────────────────────────────────────────────

# Console messages containing any of these strings are treated as failures.
FATAL_PATTERNS = [
    "failed to load component",
    "is not a type",
    "module",
    "cannot load",
    "qfatal",
    "assertion failed",
    "uncaught",
    "typeerror",
    "referenceerror",
]

def is_fatal(text: str) -> bool:
    lower = text.lower()
    return any(p in lower for p in FATAL_PATTERNS)


# ── Main test logic ────────────────────────────────────────────────────────────

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


def run_test(build_dir: Path, timeout_sec: int) -> bool:
    ensure_playwright()
    from playwright.sync_api import sync_playwright

    server = start_server(str(build_dir))
    time.sleep(0.3)

    url = f"http://localhost:{PORT}/eventcalendar.html"
    errors   = []
    warnings = []

    print(f"Loading {url} ...")

    with sync_playwright() as p:
        browser = p.chromium.launch()
        context = browser.new_context()
        page    = context.new_page()

        all_messages = []

        def on_console(msg):
            text = msg.text
            all_messages.append(f"[{msg.type}] {text}")
            if msg.type == "error" or is_fatal(text):
                errors.append(text)
            elif msg.type == "warning":
                warnings.append(text)

        page.on("console",   on_console)
        page.on("pageerror", lambda err: errors.append(f"pageerror: {err}"))

        try:
            page.goto(url, timeout=timeout_sec * 1000)
            # Qt renders into a <canvas>; wait for it to appear.
            page.wait_for_selector("canvas", timeout=timeout_sec * 1000)
            print("Canvas element found — app rendered.")
        except Exception as exc:
            errors.append(f"Navigation/render timeout: {exc}")

        browser.close()

    server.shutdown()

    print("\n--- Full console log ---")
    for m in all_messages:
        print(f"  {m}")
    print("--- End console log ---\n")

    if warnings:
        print("\nWarnings:")
        for w in warnings:
            print(f"  [!] {w}")

    if errors:
        print("\nFAILED - errors detected:")
        for e in errors:
            print(f"  [x] {e}")
        return False

    print("\nPASSED - no errors detected.")
    return True


def main():
    parser = argparse.ArgumentParser(description="Headless WASM smoke test")
    parser.add_argument("--build-dir", help="Path to WASM build output directory")
    parser.add_argument("--timeout",   type=int, default=30,
                        help="Seconds to wait for app to render (default: 30)")
    args = parser.parse_args()

    if args.build_dir:
        build_dir = Path(args.build_dir)
    else:
        build_dir = find_wasm_build_dir()

    if not build_dir or not (build_dir / "eventcalendar.html").exists():
        print("ERROR: WASM build output not found.")
        print("Run 'python scripts/build_wasm.py' first, or pass --build-dir.")
        sys.exit(1)

    print(f"Testing build: {build_dir.name}\n")
    success = run_test(build_dir, args.timeout)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
