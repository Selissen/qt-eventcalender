# Qt → Flutter Migration: Strangler Fig Strategy (Windows)

## Context

Medium-to-large Qt 6.x application (QML UI, Qt Multimedia audio, Windows desktop). Migrating incrementally to Flutter using a strangler fig pattern. Migration order is non-linear — not all features can be migrated in a clean domain-by-domain sequence.

Two concrete migration steps already identified:

1. **A self-contained tab** — separate domain and functionality, good first candidate
2. **A map component** — cross-cutting widget embedded across multiple Qt views and domains

An embedding attempt has already been made on this project.

---

## Core Architecture Decision

Two seam granularities are required simultaneously:

| Migration target | Seam type |
|---|---|
| Self-contained tab | Window-level (Flutter HWND parented to Qt main window) |
| Cross-cutting map widget | Widget-level (HWND embedding via `QWidget::createWindowContainer`) |

Both seams are served by a **single Flutter runtime** loaded as a guest DLL inside the Qt process. The Flutter engine does not need to be aware of which seam strategy is in use.

---

## Deployment Model

Flutter ships as a guest runtime inside the Qt process:

- `flutter_windows.dll` — embedder + compositor (D3D11/ANGLE or D3D12/Impeller)
- `dart.dll` — AOT runtime
- Compiled Dart snapshot

Integration is via the **Flutter Embedder C API** (`FlutterEngineRun`, `FlutterEngineCreateView`, etc.), not the standard Flutter Windows runner. This means:

- Engine lifecycle (init, shutdown, view creation) is wired manually
- Plugin registration must be done manually — the auto-generated `RegisterPlugins` from the standard runner is not available
- The Qt build system must incorporate Flutter's DLLs and snapshot as build outputs
- Hot reload works in debug builds alongside the Dart toolchain; not relevant for production

---

## Seam 1 — Tab (Window-Level)

Flutter window is Win32-parented to the Qt main window, sized and positioned to fill the tab content area. Qt's tab bar controls show/hide; Flutter owns everything inside the HWND.

```
Qt Main Window
└── Tab Content Area
    └── Flutter HWND (Win32 child, sized to fill tab area)
```

**Why this is low-risk:**
- No widget-level embedding; just window parenting
- Flutter engine renders normally; Qt positions the window
- Clean strangler fig step: Qt tab content → Flutter window in same slot

---

## Seam 2 — Map Widget (Widget-Level HWND Embedding)

The map is a cross-cutting widget appearing across multiple Qt views. The key insight: **one Flutter engine, one HWND, reparented as the user navigates** — not one engine per embed site.

Mechanism:
- `QWindow::fromWinId(flutterHwnd)` + `QWidget::createWindowContainer()` on each Qt view that hosts the map
- Only one container is active/visible at a time
- HWND is detached and reattached (Win32 `SetParent`) as the user navigates between Qt views
- Flutter engine stays alive the whole time; map state is preserved across view transitions

```
Qt View A                Qt View B
┌─────────────┐         ┌─────────────┐
│ QWidget     │         │ QWidget     │
│ ┌─────────┐ │         │ ┌─────────┐ │
│ │ Flutter │ │  ─────▶ │ │ Flutter │ │
│ │  HWND   │ │ reparent│ │  HWND   │ │
│ └─────────┘ │         │ └─────────┘ │
└─────────────┘         └─────────────┘
        └──── single FlutterEngine instance ────┘
```

**Constraint:** This approach assumes the map is not displayed in two Qt views *simultaneously*. If simultaneous instances are required, Flutter's multi-view API is needed (see below).

---

## Multi-View Considerations

If simultaneous Flutter surfaces are needed (e.g. tab and map visible at the same time), Flutter's multi-view API (landed in Flutter 3.22) is required.

**Status on Windows as of late 2025:**
- Functional but not fully stable
- Known rough edges: focus arbitration between views, plugins that assume single-view, limited tooling support
- Plan for additional integration work if this path is taken

The reparenting approach (single HWND) does **not** depend on multi-view and is the more conservative option.

---

## Event Routing

The most persistent integration cost. Both Qt's event loop and Flutter's Win32 embedder compete for:

- `WM_MOUSE*`
- `WM_KEY*`
- Focus change messages

**Recommendation:** Solve this once in a dedicated wrapper class using `QAbstractNativeEventFilter` to selectively forward messages to the Flutter HWND. Do not solve per embed site — the cost compounds.

---

## State / IPC Bridge

Flutter screens need access to Qt-side state (domain data, audio device state, etc.). Options by use case:

| Use case | Recommended mechanism |
|---|---|
| General domain state, commands | Named pipe or local socket |
| Performance-sensitive data (audio metadata, map tiles) | `dart:ffi` → shared C++ library |
| Structured bidirectional messaging | `QWebChannel`-style JS bridge (if already familiar) |

Define the bridge contract early. Retrofitting it across multiple migrated screens is expensive.

---

## Plugin Verification

Before committing Flutter to any specific screen, verify plugin Windows support:

- Map: `flutter_maplibre_gl`, `mapbox_maps_flutter`, etc. — Windows support varies; verify the specific plugin used
- Audio: no direct WASAPI access from Flutter; must go through IPC or FFI to Qt Multimedia layer during transition
- General: many plugins assume single-view and may need patching for embedder use

---

## Windows Deployment Status Summary

| Scenario | Status |
|---|---|
| Single HWND, reparented between Qt views | Solid, no experimental dependencies |
| Two simultaneous Flutter surfaces (multi-view) | Functional in Flutter 3.22+, rough edges remain |
| Flutter as guest DLL in Qt process | Supported path, requires embedder API work |
| Plugin ecosystem on Windows embedder | Patchy — verify each plugin individually |

---

## Estimated Upfront Investment

Embedder integration (engine lifecycle, plugin registration, build system wiring, event routing wrapper) is a **one-time foundational cost** before the first Flutter screen is visible inside Qt. Estimate: **2–4 weeks**, amortized across the full migration.

---

## Reference

- Flutter Embedder C API: `flutter_embedder.h` in the Flutter SDK
- `QWidget::createWindowContainer` / `QWindow::fromWinId` — Qt docs
- Flutter multi-view API: Flutter 3.22 release notes
- Precedent: Canonical's Flutter embedding in GNOME Shell (Linux, different platform, same embedder API pattern)
