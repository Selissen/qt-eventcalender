# Flutter Embedding — Testing Guide

This document covers how to test the Flutter embedding layer: automated unit tests, manual integration testing, and how to extend the test suite.

## Prerequisites

Before running any embedding tests the Flutter artifacts must be built and synced:

```bash
python scripts/check_flutter.py
```

This builds the Flutter app (`flutter build windows --release`) and copies the artifacts (`flutter_assets/`, `icudtl.dat`, `flutter_windows.dll`) next to the Qt executable. Without these the embedded Flutter views show nothing.

---

## 1 — Automated unit tests (CTest)

The embedding unit tests live under `tests/embedding/`. They use a stub Flutter C API (no real engine needed) so they run headlessly in CI without any Flutter artifacts.

### Build

Build the desktop configuration in Qt Creator (MinGW 64-bit kit). The test executables are built as part of the main build.

### Run all tests

```bash
cd "build/Desktop_Qt_6_11_0_MinGW_64_bit-RelWithDebInfo"
ctest --output-on-failure
```

### Run embedding tests only

```bash
ctest -R "tst_componentbridge|tst_navigationbridge|tst_fluttercontainer" --output-on-failure
```

### Run a single test target

```bash
ctest -R tst_navigationbridge --output-on-failure
```

### Test targets and what they cover

| Target | Source | Coverage |
|---|---|---|
| `tst_componentbridge` | `tst_componentbridge.cpp` | JSON encode/decode, invalid-JSON guard, destructor callback cleanup |
| `tst_navigationbridge` | `tst_navigationbridge.cpp` | Signal emission, Qt vs Flutter route dispatch, params forwarding, `returnedToQt`, null-container safety, empty-route guard |
| `tst_fluttercontainer` | `tst_fluttercontainer.cpp` | Engine/controller failure paths, double-init guard, pre-init method safety, messenger null before init |

---

## 2 — Manual integration testing

With Flutter artifacts synced and the Qt desktop build ready, launch the app and exercise each embedding scenario.

### 2.1 Qt → Flutter navigation

1. Launch `eventcalendar.exe`.
2. Click any toolbar button that navigates to a Flutter route (e.g. **Plans**).
3. Verify the Flutter view appears inside the Qt window (no blank area, correct size).
4. Resize the window — the Flutter HWND must follow (no gap or overflow).

### 2.2 Flutter → Qt back navigation

1. Navigate into a Flutter screen (as above).
2. Press the **Back** button inside Flutter.
3. Verify the Qt view is restored and the Flutter HWND is hidden.

### 2.3 Focus handoff

1. Navigate to a Flutter screen.
2. Click inside the Flutter area — keyboard input should go to Flutter (type into a text field if one is present).
3. Press Back to return to Qt.
4. Click a Qt widget — keyboard input should return to Qt.

### 2.4 Map component (if `FlutterMapItem` is active)

1. Open a plan that has routes.
2. Verify the embedded Flutter map renders inside the Qt plan-edit form.
3. Toggle a route on the map — verify the sidebar reflects the change.
4. Toggle a route in the sidebar — verify the map pin updates.

---

## 3 — Stub architecture (for contributors)

The stub headers live in `tests/embedding/stubs/`. They are placed on the include path **before** the real Flutter engine directory so the compiler finds the stubs first:

```cmake
set(FLUTTER_STUB_INCLUDES
    "${CMAKE_CURRENT_SOURCE_DIR}/embedding/stubs"   # stub flutter_windows.h etc.
    "${CMAKE_CURRENT_SOURCE_DIR}/embedding"          # flutter_stub.h
    "${CMAKE_CURRENT_SOURCE_DIR}/../embedding"       # production headers
    ...
)
```

`flutter_stub.cpp` provides concrete implementations of every Flutter C API function. Global state is reset by `FlutterStub::reset()` in each test's `init()` slot.

| Helper | Purpose |
|---|---|
| `FlutterStub::reset()` | Clear all recorded calls and error-injection flags |
| `FlutterStub::failNextEngineCreate()` | Make the next `FlutterDesktopEngineCreate` return `nullptr` |
| `FlutterStub::failNextControllerCreate()` | Make the next `FlutterDesktopViewControllerCreate` return `nullptr` |
| `FlutterStub::takeSends()` | Drain and return all `FlutterDesktopMessengerSend` calls |
| `FlutterStub::takeCallbacks()` | Drain and return all registered messenger callbacks |
| `FlutterStub::injectMessage(channel, payload)` | Fire a fake incoming message on a channel |

---

## 4 — Adding new embedding tests

1. Create `tests/embedding/tst_<name>.cpp` using the pattern in existing test files.
2. Include `flutter_stub.h` and the production header under test.
3. Call `FlutterStub::reset()` in `init()`.
4. Add the target to `tests/CMakeLists.txt`:

```cmake
add_embedding_test(tst_<name>
    embedding/tst_<name>.cpp
    ../embedding/<ProductionClass>.cpp
    ../embedding/<ProductionClass>.h
)
```

5. Build and run: `ctest -R tst_<name> --output-on-failure`.

---

## 5 — CI integration

All CTest targets (including embedding tests) are registered with the standard `add_test()` call and inherit the `PATH` and `QT_QPA_PLATFORM=offscreen` environment entries. Any CI runner that builds the desktop kit and runs `ctest` will pick them up automatically — no extra configuration needed.
