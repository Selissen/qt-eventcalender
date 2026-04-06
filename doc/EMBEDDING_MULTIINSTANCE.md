# Multi-Instance Component Embedding

## Purpose

This document describes the architecture and implementation plan for embedding multiple
Flutter component instances — potentially of the same type (e.g. a map) but with
independent state — inside the Qt application.

It covers the short-term requirement (one component per page, or a whole-page tab swap)
and the medium-term requirement (multiple simultaneous components across different views,
each with unique state such as planning-routes vs. overview-routes).

---

## Context: Phase 2 of the Strangler Fig Migration

The migration has two seam types that must coexist:

| Seam | Mechanism | Example |
|---|---|---|
| **Seam 1** — whole-page tab swap | `FlutterContainer` + `NavigationBridge`; one HWND fills the content area | Week view, Plans screen |
| **Seam 2** — embedded component | `FlutterComponentView` QML item; HWND is a child of one QML screen | Map widget inside a planning screen |

Both seams are already partially implemented. This plan completes Seam 2 for the
multi-instance case.

---

## API Constraint: One Engine per View Controller

`FlutterDesktopViewControllerCreate(width, height, engine)` **takes ownership** of the
engine. The API comment in `flutter_windows.h` (line ~112) states:

> This takes ownership of `engine`, so `FlutterDesktopEngineDestroy` should no longer be
> called on it, as it will be called internally when the view controller is destroyed.

Calling it twice with the same engine would cause a double-free when either controller is
destroyed. The current Flutter Windows API does **not** expose an `AddView` method that
would allow adding a second view to a running engine without transferring ownership.

**Consequence:** each `FlutterComponentView` instance owns its own Flutter engine
(Dart isolate). This is the correct model given the current API surface.

### Future: shared-engine multi-view

Flutter 3.22+ contains a multi-view API in the embedding layer
(`FlutterDesktopPluginRegistrarGetViewById` is already in the header, signalling intent).
When a stable `AddView`/`CreateAdditionalViewController` API is exposed in
`flutter_windows.h`, the `ComponentEngineFactory` can grow a shared-engine overload
and `FlutterContainer::engineRef()` (added in this plan) will provide the engine to pass
to it. No other changes will be required at that point.

---

## Memory Model (per-engine)

Each Flutter engine on Windows costs roughly 80–120 MB (Dart heap + engine DLL mappings).
The AOT snapshot (`app.so`) is the same binary for all instances; the OS shares physical
pages for read-only code sections across processes and DLL loads in the same process.
Effective marginal cost for the second and subsequent instances is therefore lower.

For the described use cases (2–3 simultaneous map components), per-engine is acceptable.
If profiling reveals pressure, the shared-engine path above becomes the mitigation.

---

## Instance Identity: `instanceId` + `dart_entrypoint_argv`

The problem: two `FlutterComponentView` instances of the same type (e.g. both using
`entrypoint: "mapComponentMain"`) would both listen on `"com.eventcalendar/map"` and
receive each other's messages.

The solution: each instance carries a unique `instanceId` string (set from QML). The C++
layer threads it in two places:

1. **Channel name** — the full channel becomes `channel + "/" + instanceId`, e.g.
   `"com.eventcalendar/map/planning"`. Each bridge is therefore scoped to exactly one
   instance.

2. **Dart entry-point argument** — `FlutterDesktopEngineProperties.dart_entrypoint_argv`
   is set to `["--instanceId=<id>"]`. The Dart entry point reads this argument and
   constructs the same channel name, ensuring C++ and Dart agree without any additional
   handshake.

QML usage (no C++ changes needed at the call site):

```qml
// Planning screen
FlutterComponentView {
    entrypoint:  "mapComponentMain"
    channel:     "com.eventcalendar/map"
    instanceId:  "planning"
    // actual channel used: "com.eventcalendar/map/planning"
}

// Overview screen
FlutterComponentView {
    entrypoint:  "mapComponentMain"
    channel:     "com.eventcalendar/map"
    instanceId:  "overview"
    // actual channel used: "com.eventcalendar/map/overview"
}
```

When `instanceId` is empty (backwards-compatible default), the channel is used as-is and
no argv is added — existing QML that omits `instanceId` continues to work unchanged.

---

## Focus Handling

`FlutterFocusFilter` is for **Seam 1 only** (full-page Flutter navigation). It redirects
`WM_SETFOCUS` to the `FlutterContainer` HWND when `isEmbeddedVisible()` is true.

`FlutterComponentView` creates `WS_CHILD | WS_CLIPSIBLINGS` HWNDs. Win32's natural child-
window focus propagation handles these correctly: a click on the Flutter child sends
`WM_SETFOCUS` directly to that child, without triggering the parent-level filter. No
changes to `FlutterFocusFilter` are needed for Seam 2.

If Seam 1 multi-view is ever needed (two full-page Flutter views simultaneously), the
filter would need generalising to a tracked set of HWNDs. That is deferred.

---

## Implementation Steps

### Step 1 — Document (this file) ✅

### Step 2 — C++: `instanceId` in `ComponentEngineFactory` and `FlutterComponentView`

**`ComponentEngineFactory.h`** — add `instanceId` parameter to both overloads:

```cpp
static FlutterDesktopViewControllerRef createController(
    const QString& entrypoint,
    const QString& instanceId = {},   // NEW: passed as --instanceId= argv
    int initialWidth  = 400,
    int initialHeight = 300);

static FlutterDesktopViewControllerRef createController(
    const QString& assetsPath,
    const QString& icuDataPath,
    const QString& aotLibraryPath,
    const QString& entrypoint,
    const QString& instanceId = {},   // NEW
    int initialWidth  = 400,
    int initialHeight = 300);
```

**`ComponentEngineFactory.cpp`** — populate `dart_entrypoint_argv` when `instanceId` is
non-empty:

```cpp
QByteArray idArg;
std::vector<const char*> argv;
if (!instanceId.isEmpty()) {
    idArg = ("--instanceId=" + instanceId).toUtf8();
    argv.push_back(idArg.constData());
}
props.dart_entrypoint_argc = static_cast<int>(argv.size());
props.dart_entrypoint_argv = argv.empty() ? nullptr : argv.data();
```

`idArg` must outlive `FlutterDesktopEngineCreate` (the API deep-copies it, so a local
`QByteArray` in scope for the call is sufficient).

**`FlutterComponentView.h`** — add property:

```cpp
Q_PROPERTY(QString instanceId READ instanceId WRITE setInstanceId
                               NOTIFY instanceIdChanged)
```

**`FlutterComponentView.cpp`** — in `ensureEngine()`:

```cpp
const QString fullChannel = instanceId_.isEmpty()
    ? channel_
    : channel_ + QStringLiteral("/") + instanceId_;
// use fullChannel for ComponentBridge, pass instanceId_ to createController()
```

### Step 3 — C++: `FlutterContainer::engineRef()`

Add read-only accessor to `FlutterContainer`:

```cpp
// FlutterContainer.h
FlutterDesktopEngineRef engineRef() const { return engine_; }
```

No implementation change needed (engine_ is already a member). This accessor enables:
- Diagnostics and testing (confirm the engine is non-null after init)
- Future shared-engine overload in `ComponentEngineFactory`
- Components that need to reach the same messenger as the primary navigation engine

### Step 4 — Dart: instance-aware `mapComponentMain`

**`flutter/app/lib/main.dart`** — signature change:

```dart
@pragma('vm:entry-point')
void mapComponentMain(List<String> args) {
  final instanceId = _parseArg(args, '--instanceId=') ?? 'default';
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MapComponentApp(instanceId: instanceId));
}

String? _parseArg(List<String> args, String prefix) {
  for (final a in args) {
    if (a.startsWith(prefix)) return a.substring(prefix.length);
  }
  return null;
}
```

**`flutter/app/lib/screens/map_component.dart`** — thread `instanceId` into the binding:

```dart
class MapComponentApp extends StatelessWidget {
  const MapComponentApp({super.key, required this.instanceId});
  final String instanceId;
  // build: pass instanceId to MapComponentScreen
}

class MapComponentScreen extends StatefulWidget {
  const MapComponentScreen({super.key, required this.instanceId});
  ...
}

class _MapComponentScreenState extends State<MapComponentScreen> {
  late final _binding = FlutterComponentBinding(
    channel: 'com.eventcalendar/map/${widget.instanceId}',
    onMessage: _handleMessage,
  );
  ...
}
```

### Step 5 — Tests

**`tests/embedding/flutter_stub.h/.cpp`** — extend `FlutterStub` to capture
`dart_entrypoint_argv`:

```cpp
struct EngineCreateRecord {
    std::string              entrypoint;
    std::vector<std::string> argv;
};
EngineCreateRecord takeLastEngineCreate();   // returns and clears
```

In `FlutterDesktopEngineCreate`, populate `EngineCreateRecord` from `props`.

**`tests/embedding/tst_componentenginefactory.cpp`** — new test cases:

- `instanceIdPassedAsArgv`: create controller with `instanceId="planning"`, verify
  `FlutterStub::takeLastEngineCreate().argv` contains `"--instanceId=planning"`.
- `emptyInstanceIdProducesNoArgv`: create without instanceId, verify argv is empty.

---

## Adding a New Component Type

Follow this pattern for any new component (e.g. a chart):

1. Write a `@pragma('vm:entry-point') void chartComponentMain(List<String> args)` in
   `flutter/app/lib/main.dart` — parse `instanceId`, call `runApp(ChartApp(...))`.

2. Create `flutter/app/lib/screens/chart_component.dart` with a `FlutterComponentBinding`
   using channel `'com.eventcalendar/chart/$instanceId'`.

3. In QML:
   ```qml
   FlutterComponentView {
       entrypoint: "chartComponentMain"
       channel:    "com.eventcalendar/chart"
       instanceId: "weekly"
   }
   ```

No C++ changes are required for new component types.

---

## What Is Not Done Here

| Concern | Status | Notes |
|---|---|---|
| Shared-engine multi-view | Deferred | Blocked by `flutter_windows.h` API; revisit when `AddView` is stable |
| Multi-HWND `FlutterFocusFilter` | Deferred | Only needed for simultaneous full-page Flutter views |
| Component hot-reload | N/A | Not relevant for production builds |
| Cross-component state sharing | By design excluded | Each engine has its own isolate; share state via the Qt/C++ layer or gRPC server |
