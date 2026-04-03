# Qt Flutter Embedding — Plugin Extraction Plan

Goal: extract the generic Flutter embedding layer into a standalone, reusable CMake library (`QtFlutterEmbedding`) that any Qt project can consume, while keeping app-specific code in `eventcalendar`.

Platform scope: **Windows only** (Win32 HWND embedding). No Linux/macOS abstraction layer required.

---

## Phase 1 — Extract generic classes into a standalone library

**What:** Move the seven generic embedding classes out of `eventcalendar` into a new top-level directory `QtFlutterEmbedding/` with its own `CMakeLists.txt`.

**Files to move:**
- `embedding/FlutterContainer.*`
- `embedding/FlutterFocusFilter.*`
- `embedding/ComponentBridge.*`
- `embedding/ComponentEngineFactory.*`
- `embedding/FlutterComponentView.*`
- `embedding/FlutterWidgetProxy.*`
- `embedding/NavigationBridge.*`

**Files that stay in `eventcalendar/embedding/`:**
- `FlutterMapItem.*` (app-specific channel + route)
- `flutter_constants.h` (app-specific channel strings; the plugin will not define these)

**Deliverables:**
- `QtFlutterEmbedding/CMakeLists.txt` — builds a static library target `QtFlutterEmbedding::Core`
- `QtFlutterEmbedding/` contains all moved headers and sources
- `eventcalendar` `CMakeLists.txt` updated to `add_subdirectory(QtFlutterEmbedding)` and `target_link_libraries(... QtFlutterEmbedding::Core)`
- All existing tests still pass

---

## Phase 2 — CMake package config (find_package support)

**What:** Add proper CMake install rules and a package config file so other projects can consume the library with `find_package(QtFlutterEmbedding REQUIRED)` without copying source files.

**Deliverables:**
- `install(TARGETS QtFlutterEmbedding::Core ...)` with `EXPORT`
- `install(FILES ...)` for all public headers
- `QtFlutterEmbeddingConfig.cmake.in` + configured `QtFlutterEmbeddingConfig.cmake`
- `QtFlutterEmbeddingConfigVersion.cmake`
- A `VERSION` file at the library root (start at `0.1.0`)
- Verified: a minimal test project outside `eventcalendar` can find and link the library via `find_package`

---

## Phase 3 — QML type registration

**What:** Register `FlutterComponentView` (and optionally `FlutterWidgetProxy`) as QML types under a `QtFlutterEmbedding` URI so host projects can use the component directly from QML without any C++ wiring.

**Deliverables:**
- `qt_add_qml_module` in `QtFlutterEmbedding/CMakeLists.txt` registering URI `QtFlutterEmbedding`
- `QML_ELEMENT` (or `qmlRegisterType`) on `FlutterComponentView`
- Example QML usage in a README snippet:
  ```qml
  import QtFlutterEmbedding
  FlutterComponentView {
      route: "/my-component"
      anchors.fill: parent
  }
  ```
- `eventcalendar` QML updated to use the registered type where applicable
- WASM guard confirmed: the QML type registration must be a no-op on WASM (existing `#ifndef Q_OS_WASM` pattern)

---

## Phase 4 — Configurable asset paths

**What:** `ComponentEngineFactory` currently looks for `flutter_assets/`, `icudtl.dat`, and `app.so` next to the executable. A plugin must let the host specify where artifacts live.

**Deliverables:**
- `ComponentEngineFactory` gains a static or instance-level `setArtifactsDir(const QString& path)` (or takes it as a parameter to `createController`)
- Default behaviour unchanged: falls back to `QCoreApplication::applicationDirPath()` when not set, so `eventcalendar` needs no change
- `FlutterMapItem` and any other call sites updated to pass the path explicitly if they need a non-default location
- Unit test covering the "artifacts dir not found → returns nullptr" path

---

## Phase 5 — Engine sharing (engine groups)

**What:** Each `ComponentEngineFactory::createController` call currently spawns a separate Flutter engine (separate Dart VM). Flutter supports engine groups where multiple view controllers share one Dart VM, which is faster to spawn and cheaper on memory.

**Deliverables:**
- `FlutterEngineGroup` wrapper class (Windows: `FlutterDesktopEngineGroupCreate` / `...SpawnController`)
- `ComponentEngineFactory` gains a `shared()` static factory that reuses one `FlutterEngineGroup` per process
- Existing `createController` path kept as the "isolated engine" option for cases where isolation is needed
- `FlutterContainer` and `FlutterMapItem` updated to use the shared factory by default
- Memory/startup time improvement documented in commit message

---

## Phase 6 — Error signals

**What:** All current failures are reported via `qWarning()` only. A reusable plugin must give host applications a way to react to errors (e.g. show a fallback UI, log to telemetry).

**Deliverables:**
- `FlutterContainer` gains `void initializationFailed(const QString& reason)` signal
- `ComponentBridge` gains `void sendFailed(const QString& reason)` signal
- `FlutterComponentView` gains `void engineError(const QString& reason)` signal (wraps `FlutterContainer::initializationFailed`)
- `qWarning()` calls retained alongside signals (not replaced)
- `eventcalendar` connects to `engineError` on `FlutterMapItem` and logs/hides the map area gracefully
- Unit tests: verify signals fire on stub-injected failure paths

---

## Execution order

Phases are independent after Phase 1 but Phase 1 must go first (everything else builds on the extracted library).

| Phase | Depends on | Effort |
|---|---|---|
| 1 — Extract library | — | Medium (file moves + CMake wiring) |
| 2 — find_package | 1 | Small |
| 3 — QML types | 1 | Small–Medium |
| 4 — Asset paths | 1 | Small |
| 5 — Engine sharing | 1, 4 | Large |
| 6 — Error signals | 1 | Small |

Recommended order: **1 → 2 → 4 → 6 → 3 → 5**
(Get the library solid and its API clean before adding the QML layer; engine sharing last as it carries the most risk.)
