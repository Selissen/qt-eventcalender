# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Qt 6 Quick Controls 2 (Material theme) calendar app. Plans (events) are stored in SQLite via `QSqlDatabase`. The app targets both desktop (Windows/macOS) and WebAssembly.

## Build system

The project is built through **Qt Creator** using CMake. Two active configurations live under `build/`:

| Directory prefix | Kit |
|---|---|
| `Desktop_Qt_6_11_0_MinGW_64_bit-*` | Desktop (MinGW 64-bit) |
| `WebAssembly_Qt_6_11_0_multi_threaded-*` | Emscripten WASM |

### Desktop build (from Qt Creator)
Open Qt Creator → configure with the MinGW kit → Build.

### WASM build (command line)
Must be run **from inside the build directory** with `EMSDK` set:

```bash
cd "X:/Projects/eventcalendar/build/WebAssembly_Qt_6_11_0_multi_threaded-RelWithDebInfo"
EMSDK="X:/emsdk" "X:/Qt/Tools/QtCreator/bin/jom/jom.exe"
```

`cmake` is not on PATH; the executable is at `X:/Qt/Tools/CMake_64/bin/cmake.exe`. If you need to reconfigure (e.g., after deleting CMakeCache.txt), re-pass the `EMSDK` env var and the original Emscripten toolchain file — the WASM kit loses its toolchain without it.

### Serve and test WASM locally

```bash
# Rebuild the WASM target (finds the Qt Creator build dir automatically):
python scripts/build_wasm.py [--release | --debug]

# Serve with required COOP/COEP headers and open browser:
python scripts/serve_wasm.py

# Headless smoke test (auto-installs Playwright on first run):
python scripts/test_wasm.py

# Build then test in one step:
python scripts/check_wasm.py
```

`test_wasm.py` starts a local HTTP server on port 18765, loads the app in headless Chromium, waits for the `<canvas>` element Qt renders into, and reports any console errors. It exits 0 on pass, 1 on failure.

### Run desktop tests

Tests are CTest executables under `tests/`. Build the desktop configuration in Qt Creator, then:

```bash
cd "build/Desktop_Qt_6_11_0_MinGW_64_bit-RelWithDebInfo"
ctest --output-on-failure
```

Run a single test by name:
```bash
ctest -R tst_datetimeutils --output-on-failure
```

## Architecture

### QML module structure

All QML is registered under the `App` URI via `qt_add_qml_module`. The backing target is `eventcalendar_lib` (a static library), which causes Qt to generate a linkable plugin `eventcalendar_libplugin`. This plugin is explicitly linked into the `eventcalendar` executable alongside `qt_import_qml_plugins`. This arrangement is **required for WASM** — without it, Emscripten dead-code elimination strips the static initializers that register QML types.

```
eventcalendar (executable)
  └── eventcalendar_lib (static, QML module "App")
        └── eventcalendar_libplugin (generated static plugin, explicitly linked)
```

`qt_policy(SET QTP0004 NEW)` is set in `CMakeLists.txt`. This is required for Qt 6.8+ WASM/static builds: without it the engine cannot discover types in subdirectories (`atoms/`, `organisms/`, etc.) because per-subdirectory `qmldir` files are not generated.

### QML layer conventions

QML files follow an atomic design hierarchy (directory = layer):

| Directory | Role |
|---|---|
| `atoms/` | Primitive reusable controls (e.g., `DatePickerField`) |
| `molecules/` | Composites of atoms (e.g., `MonthGridDelegate`) |
| `organisms/` | Feature-level components (sidebars, footer) |
| `templates/` | Page-level layout skeletons (`MonthView`, `WeekView`) |
| `pages/` | Application root (`eventcalendar.qml`) |

All QML imports `App` and uses `CalendarUtils` (singleton) and `DateTimeUtils` (singleton) for date math and formatting.

### C++ / QML boundary

| C++ class | QML name | Role |
|---|---|---|
| `CalendarUtils` | `CalendarUtils` (singleton) | ISO week numbers, navigation, week-start calculation |
| `DateTimeUtils` | `DateTimeUtils` (singleton) | Canonical datetime format (`dd/MM/yyyy HH:mm`), parse/format |
| `SqlPlanDatabase` | `PlanDatabase` (uncreatable) | SQLite CRUD for plans; created in `main()`, passed via `setInitialProperties` |
| `PlanModel` | `PlanModel` | `QAbstractListModel` filtered by date range and unit |
| `Plan` | — | Plain struct: id, name, startDate, endDate, unitId, unitName, routeIds |

`SqlPlanDatabase` is instantiated once in `main()` and injected as a required property on the root QML object. All views receive it through property binding.

### WASM persistence

On WASM, `SqlPlanDatabase` stores the SQLite database in `QStandardPaths::AppDataLocation`, which maps to IndexedDB (persistent across page reloads). On desktop it uses `:memory:`. Schema uses `CREATE TABLE IF NOT EXISTS` and `INSERT OR IGNORE` so re-opening an existing WASM database is safe.

### Known WASM quirks

- `Qt.ImhDateTime` is `undefined` on WASM (input method hints unsupported). `DatePickerField.qml` uses `Qt.ImhDateTime || 0` as a fallback.
- The QML entry point URL is `qrc:/App/pages/eventcalendar.qml` — the `/App/` prefix comes from the library module's resource target path with URI `"App"`.
- COOP/COEP HTTP headers (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`) are required to serve the WASM build; `serve_wasm.py` and `test_wasm.py` both add them automatically.
