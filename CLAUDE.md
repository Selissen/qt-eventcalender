# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Qt 6 Quick Controls 2 (Material theme) calendar app. Plans (events) are stored in SQLite via `QSqlDatabase`. The app targets both desktop (Windows/macOS) and WebAssembly.

A parallel Flutter migration is underway using the **Strangler Fig pattern** (see `doc/FLUTTER.md`). Phase 0 (embedding validated) and Phase 1 (embedded inside Qt window + navigation bridge) are complete. The Flutter layer lives under `flutter/` and is only active on desktop when `EC_FLUTTER_EMBED_ENABLED=ON`.

## Verification requirements

Any change that touches `CMakeLists.txt`, `eventcalendar.cpp`, C++ headers/sources registered with `QML_ELEMENT`/`QML_SINGLETON`/`QML_UNCREATABLE`, or QML files **must be verified on both targets before being considered done**:

1. **Desktop** — build in Qt Creator with the MinGW kit and confirm the app launches without errors.
2. **WASM** — run `python scripts/check_wasm.py` (builds + headless smoke test) and confirm it exits 0.

Any change that touches `flutter/`, `FlutterContainer.*`, `FlutterWidgetProxy.*`, `ComponentBridge.*`, `ComponentEngineFactory.*`, `NavigationBridge.*`, or `FlutterFocusFilter.*` must also:

3. **Flutter** — run `python scripts/check_flutter.py` (builds Flutter + syncs artifacts) and confirm it exits 0, then rebuild the Qt desktop target and confirm the embedding still works.

Do not mark a task complete or propose a commit until all relevant checks pass (or explicitly confirm with the user that only a subset of targets is relevant).

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

### Flutter build and artifact sync

The Flutter app must be built separately and its artifacts copied next to the Qt executable before the embedding activates:

```bash
# Build Flutter and sync artifacts in one step:
python scripts/check_flutter.py

# Or individually:
python scripts/build_flutter.py          # flutter build windows --release
python scripts/sync_flutter_artifacts.py # copies flutter_assets/, icudtl.dat, app.so, flutter_windows.dll
```

`sync_flutter_artifacts.py` auto-detects the most recently modified Desktop Qt build directory under `build/`. Pass `--build-dir PATH` to override.

The Flutter engine artifacts (headers + import lib) are at `X:/Flutter/bin/cache/artifacts/engine/windows-x64/`. CMake reads this path from the `FLUTTER_ENGINE_DIR` cache variable (defaulted in `CMakeLists.txt`).

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
| `molecules/` | Composites of atoms (e.g., `MonthGridDelegate`, `WeekPlanCell`) |
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

`NavigationBridge` is injected as a QML context property (`navBridge`) before `engine.load()` when `EC_FLUTTER_EMBED_ENABLED` is defined. QML calls `navBridge.navigateTo("/route")` to switch to a Flutter screen.

### WASM persistence

On WASM, `SqlPlanDatabase` stores the SQLite database in `QStandardPaths::AppDataLocation`, which maps to IndexedDB (persistent across page reloads). On desktop it uses `:memory:`. Schema uses `CREATE TABLE IF NOT EXISTS` and `INSERT OR IGNORE` so re-opening an existing WASM database is safe.

### Sync layer — `PlanSyncManager`

`PlanSyncManager` mirrors local SQLite mutations to a remote backend. It is instantiated in `main()` alongside `SqlPlanDatabase` and calls `start()` to connect signals and trigger an initial reference-data pull (units, routes). Transport is selected at **compile time**:

| Condition | Transport |
|---|---|
| `EC_GRPC_ENABLED` defined | Qt gRPC via `QGrpcHttp2Channel` (`CalendarService` stub) |
| `Q_OS_WASM` defined | `QNetworkAccessManager` REST/JSON |
| Neither | No-op (logs a message; app runs locally only) |

`EC_GRPC_ENABLED` is defined by CMakeLists.txt when `Qt6::Protobuf` and `Qt6::Grpc` are found. The find is `OPTIONAL_COMPONENTS` so the build succeeds even when the Qt gRPC addon is not installed.

**To enable gRPC on desktop:** two things must be present:
1. Qt gRPC addon — cmake files are already at `X:/Qt/6.11.0/mingw_64/lib/cmake/Qt6Grpc` and `Qt6Protobuf` (installed). `qtprotobufgen.exe` and `qtgrpcgen.exe` are at `X:/Qt/6.11.0/mingw_64/bin/`.
2. **`protoc.exe`** (Google's protobuf compiler) — `qtprotobufgen.exe` is a *plugin* for `protoc`, not a standalone replacement. `protoc` must be on `PATH`. Install via: `winget install protobuf` or `choco install protoc` or download from https://github.com/protocolbuffers/protobuf/releases. Once on PATH, CMake's `FindWrapProtoc.cmake` will find it automatically and `EC_GRPC_ENABLED` will be defined.

**Server URL** is a placeholder in `eventcalendar.cpp`:
- Desktop: `http://localhost:50051` (gRPC)
- WASM: `http://localhost:8080` (REST)

`SqlPlanDatabase` gains three narrow signals (`planAdded(int)`, `planUpdated(int)`, `planDeleted(int)`) emitted after each successful mutation. `PlanSyncManager` connects to these to push changes. Reference data updates use `setUnits()`/`setRoutes()` C++ methods (not QML-invokable) that do `INSERT OR REPLACE` into the local SQLite tables.

### QML ↔ C++ data boundary pattern

`QAbstractListModel` subclasses are **not directly iterable** in QML JavaScript. For any computation that needs to loop over all records (e.g. building a grid layout), expose a `Q_INVOKABLE` method returning `QVariantList` of `QVariantMap` instead.

Established pattern — `SqlPlanDatabase::plansForRangeQML` returns each plan as a `QVariantMap` with keys: `planId`, `name`, `startDate`, `endDate`, `unitId`, `unitName`, `routeIds`. Follow the same shape for any future bulk-query methods.

### Desktop import path quirk

Qt generates **two** copies of `App/qmldir` when the QML module uses a static library backing target:
- Filesystem copy in the build directory — has `prefer :/` (for AoT, not linked into binary)
- Embedded resource copy — has `prefer :/App/` (correct, is linked)

The engine finds the filesystem copy first and resolves all type URLs as `qrc:/organisms/...` etc., which don't exist in the binary — causing a silent startup failure (`objectCreated` fires with `null`).

**Fix (already applied in `eventcalendar.cpp`):** `engine.addImportPath(QStringLiteral("qrc:/"))` before `engine.load()` forces the engine to search resources first, where it finds the correct qmldir.

If the app silently exits on desktop after any CMake/module restructuring, this is the first thing to check.

### Flutter embedding layer

The Flutter embedding is **desktop-only** and guarded by `#ifdef EC_FLUTTER_EMBED_ENABLED`. WASM builds are unaffected.

#### CMake options

| Option | Default | Description |
|---|---|---|
| `EC_FLUTTER_EMBED_ENABLED` | `ON` | Enable Flutter embedding (desktop only) |
| `FLUTTER_ENGINE_DIR` | `X:/Flutter/bin/cache/artifacts/engine/windows-x64` | Path to Flutter Windows engine artifacts |

#### C++ embedding classes

| File | Role |
|---|---|
| `FlutterContainer` | Owns the Flutter engine + view controller. Embeds Flutter's HWND as a Win32 child of the `QQuickWindow`. Exposes `embedInto()`, `showEmbedded()`, `hideEmbedded()`, `resizeEmbedded()`, `messenger()`. |
| `FlutterFocusFilter` | `QAbstractNativeEventFilter` — forwards `WM_SETFOCUS` to Flutter's HWND only when Flutter is visible. |
| `NavigationBridge` | `QObject` exposed to QML as `navBridge`. `navigateTo(route)` sends the route via `FlutterDesktopMessengerSend` on the `"navigation"` channel and calls `showEmbedded()`. `navigateToQt()` calls `hideEmbedded()`. `listenForBackNavigation()` registers a callback on `"navigation/back"` so Flutter can return to Qt. |

#### Navigation protocol

| Direction | Channel | Encoding | Trigger |
|---|---|---|---|
| Qt → Flutter | `"navigation"` | Raw UTF-8 route string | `navBridge.navigateTo("/route")` from QML or C++ |
| Flutter → Qt | `"navigation/back"` | Any string (ignored) | `backChannel.send('back')` from Dart |

`navBridge` is set as a QML context property before `engine.load()`, so any QML file can call `navBridge.navigateTo(route)` directly. Guard with `typeof navBridge !== "undefined"` for WASM compatibility.

#### Flutter monorepo layout

```
flutter/
  app/                        # Flutter entry point (main.dart, go_router, nav channel)
  packages/
    core/                     # gRPC client factory, CalendarServiceClient provider,
    │                         #   generated Dart proto stubs (proto/calendar.pb*.dart)
    design_system/            # AppTheme, AppButton, AppTextField, AppSidebar,
                              #   LoadingView, ErrorView, EmptyView
```

Proto stubs in `flutter/packages/core/lib/src/proto/` are generated from `proto/calendar.proto` via:
```bash
protoc --dart_out=grpc:flutter/packages/core/lib/src/proto \
       --proto_path=proto \
       --plugin=protoc-gen-dart="C:/Users/roald/AppData/Local/Pub/Cache/bin/protoc-gen-dart.bat" \
       calendar.proto
```
Re-run whenever `proto/calendar.proto` changes.

#### Strangler Fig phase status

| Phase | Status | Description |
|---|---|---|
| 0 | ✅ Done | Embedding validated — Flutter engine initialises inside Qt window |
| 1 | ✅ Done | Navigation bridge wired — toolbar button + back channel work |
| 2 | 🔄 In progress | Component embedding + screen migration infrastructure in place |
| 3 | Pending | Flutter becomes navigation owner; Qt shell retired |

#### Phase 2 C++ additions

| File | Role |
|---|---|
| `FlutterWidgetProxy` | `QWidget` layout slot for a single Flutter component within a Qt screen. Relays resize/show/hide to the Flutter HWND. Use `activate()` after the proxy is visible. |
| `ComponentBridge` | Bidirectional JSON bridge per component via `FlutterDesktopMessengerSend`. Channel convention: `com.eventcalendar/<name>`. |
| `ComponentEngineFactory` | Creates a Flutter engine + view controller per component, passing `COMPONENT_ROUTE` via `--dart-define` so Flutter renders the right component. |

#### Phase 2 Flutter additions

| Path | Role |
|---|---|
| `flutter/packages/core/lib/src/providers/plans_provider.dart` | `plansProvider` — accumulates `SubscribePlans` gRPC stream into a live `List<Plan>` |
| `flutter/packages/feature_plans/` | Migrated plans list screen using `plansProvider` + `AppScaffold` |
| `flutter/app/lib/router.dart` | GoRouter registry — add a `GoRoute` here for every migrated screen |
| `design_system`: `AppScaffold`, `AppDialog`, `AppLoadingSpinner`, `AppErrorView` | Screen-level primitives; use instead of raw Scaffold/AlertDialog on all migrated screens |

#### Adding a new migrated screen (Phase 2 procedure)

1. Create `flutter/packages/feature_<name>/` with `flutter create --template=package`
2. Add providers in `flutter/packages/core/lib/src/providers/<name>_provider.dart`
3. Build the screen using only `design_system` components; all data via Riverpod
4. Add a `GoRoute(path: '/<name>', ...)` in `flutter/app/lib/router.dart`
5. Add `"/<name>"` to `kFlutterRoutes` in `NavigationBridge.cpp`
6. Add the feature package as a dependency in `flutter/app/pubspec.yaml`
7. Shadow the Qt screen for one sprint, then delete it

### Known WASM quirks

- `Qt.ImhDateTime` is `undefined` on WASM (input method hints unsupported). `DatePickerField.qml` uses `Qt.ImhDateTime || 0` as a fallback.
- The QML entry point URL is `qrc:/App/pages/eventcalendar.qml` — the `/App/` prefix comes from the library module's resource target path with URI `"App"`.
- COOP/COEP HTTP headers (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`) are required to serve the WASM build; `serve_wasm.py` and `test_wasm.py` both add them automatically.
