# Qt → Flutter Migration Instructions
## For use with Claude Code (CLI)

This document provides structured, actionable instructions for migrating a large Qt desktop application (Windows only) to Flutter using the **Strangler Fig pattern with Flutter embedded inside the Qt shell** (Option A). The app communicates exclusively via gRPC and REST services.

---

## Constraints & Context

- **Platform**: Windows only
- **Deployment**: Single application — no side-by-side process deployment permitted
- **App size**: Large (50–100 screens)
- **Backend**: gRPC (including server-side streaming) + REST
- **Strategy**: Flutter embedded inside Qt shell via Win32 HWND hosting
- **Migration pattern**: Strangler Fig — Qt shell survives until Flutter covers >80% of screens
- **Team**: Mixed Flutter experience

---

## Phase 0 — Foundation & Embedding Validation

> Goal: Prove the embedding works on target hardware. Do not migrate any screens yet.

### 0.1 Flutter Project Structure

Create a Flutter project with a package-based monorepo layout:

```
/app                   # Main Flutter app (shell entry point)
/packages
  /core                # gRPC stubs, REST clients, shared models
  /design_system       # All shared widgets, tokens, themes
  /feature_<name>      # One package per migrated feature/screen group
```

Commands:
```bash
flutter create --platforms=windows app
cd app
flutter pub add grpc protobuf dio riverpod flutter_riverpod
```

Enforce this structure before writing any feature code.

### 0.2 Protobuf / gRPC Codegen

Install the Dart protoc plugin and generate stubs from existing `.proto` files:

```bash
dart pub global activate protoc_plugin
protoc --dart_out=grpc:packages/core/lib/src/proto \
       --proto_path=path/to/your/protos \
       your_service.proto
```

Add to CI so stubs regenerate automatically when `.proto` files change. Place generated files in `packages/core/lib/src/proto/` and export from `packages/core/lib/core.dart`.

### 0.3 gRPC Client Setup (Dart)

In `packages/core`, create a gRPC channel factory:

```dart
// packages/core/lib/src/grpc_client.dart
import 'package:grpc/grpc.dart';

class GrpcClientFactory {
  static ClientChannel create({
    required String host,
    required int port,
  }) {
    return ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(), // or TLS config
      ),
    );
  }
}
```

Expose gRPC stubs and REST clients as Riverpod providers:

```dart
// packages/core/lib/src/providers.dart
final grpcChannelProvider = Provider<ClientChannel>((ref) {
  return GrpcClientFactory.create(host: 'localhost', port: 50051);
});

final myServiceStubProvider = Provider<MyServiceClient>((ref) {
  return MyServiceClient(ref.watch(grpcChannelProvider));
});
```

### 0.4 Real-Time Streaming Pattern

Use `StreamProvider` for all gRPC server-streaming calls:

```dart
final telemetryProvider = StreamProvider.autoDispose<TelemetryUpdate>((ref) {
  final stub = ref.watch(myServiceStubProvider);
  return stub.streamTelemetry(TelemetryRequest());
});
```

Consume in widgets with `.when(data:, loading:, error:)`. This is the standard pattern for all streaming screens — enforce it across the team.

### 0.5 Win32 Embedding — Qt Side

In your Qt project, add the following to host the Flutter HWND:

**CMakeLists.txt** — link against Flutter Windows embedder:
```cmake
target_link_libraries(MyQtApp PRIVATE
    flutter_windows.dll
)
target_include_directories(MyQtApp PRIVATE
    path/to/flutter/windows/embedder
)
```

**FlutterContainer.h**:
```cpp
#pragma once
#include <QWidget>
#include <QWindow>
#include <flutter/flutter_windows.h>

class FlutterContainer : public QWidget {
    Q_OBJECT
public:
    explicit FlutterContainer(QWidget* parent = nullptr);
    ~FlutterContainer();

    bool initialize(const QString& assetsPath, const QString& icuPath);

protected:
    void resizeEvent(QResizeEvent* event) override;
    bool nativeEvent(const QByteArray& eventType,
                     void* message, qintptr* result) override;

private:
    FlutterDesktopEngineRef engine_ = nullptr;
    FlutterDesktopViewControllerRef controller_ = nullptr;
    QWindow* flutter_window_ = nullptr;
    QWidget* container_widget_ = nullptr;
};
```

**FlutterContainer.cpp**:
```cpp
#include "FlutterContainer.h"
#include <QResizeEvent>
#include <QTimer>
#include <QWindow>

FlutterContainer::FlutterContainer(QWidget* parent) : QWidget(parent) {
    setAttribute(Qt::WA_NativeWindow);
    setAttribute(Qt::WA_DontCreateNativeAncestors);
}

bool FlutterContainer::initialize(const QString& assetsPath,
                                  const QString& icuPath) {
    FlutterDesktopEngineProperties props = {};
    props.assets_path = assetsPath.toStdWString().c_str();
    props.icu_data_path = icuPath.toStdWString().c_str();

    engine_ = FlutterDesktopEngineCreate(&props);
    if (!engine_) return false;

    controller_ = FlutterDesktopViewControllerCreate(width(), height(), engine_);
    if (!controller_) return false;

    HWND flutter_hwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    flutter_window_ = QWindow::fromWinId((WId)flutter_hwnd);
    container_widget_ = QWidget::createWindowContainer(
        flutter_window_, this);
    container_widget_->setGeometry(0, 0, width(), height());

    // Drive Flutter's message loop from Qt's main thread
    auto* timer = new QTimer(this);
    connect(timer, &QTimer::timeout, [this]() {
        if (engine_) FlutterDesktopEngineProcessMessages(engine_);
    });
    timer->start(16); // ~60fps tick

    return true;
}

void FlutterContainer::resizeEvent(QResizeEvent* event) {
    QWidget::resizeEvent(event);
    if (container_widget_) {
        container_widget_->setGeometry(0, 0,
            event->size().width(), event->size().height());
    }
}

FlutterContainer::~FlutterContainer() {
    if (controller_) FlutterDesktopViewControllerDestroy(controller_);
    if (engine_) FlutterDesktopEngineDestroy(engine_);
}
```

### 0.6 Fix Focus Routing

Qt captures keyboard focus before it reaches the Flutter HWND. Install a native event filter:

```cpp
class FlutterFocusFilter : public QAbstractNativeEventFilter {
public:
    explicit FlutterFocusFilter(HWND flutterHwnd)
        : flutter_hwnd_(flutterHwnd) {}

    bool nativeEventFilter(const QByteArray& eventType,
                           void* message, qintptr*) override {
        MSG* msg = static_cast<MSG*>(message);
        if (msg->message == WM_SETFOCUS) {
            SetFocus(flutter_hwnd_);
        }
        return false;
    }
private:
    HWND flutter_hwnd_;
};

// Register in main() or after FlutterContainer::initialize():
qApp->installNativeEventFilter(
    new FlutterFocusFilter(flutter_hwnd));
```

### 0.7 Fix HiDPI / DPI Scaling

Prevent double-scaling — Qt and Flutter each scale independently:

```cpp
// In main() before QApplication construction:
QApplication::setAttribute(Qt::AA_DisableHighDpiScaling);

// Alternatively, set DPI awareness via manifest or:
SetProcessDpiAwarenessContext(
    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
```

Test on both 100% and 150%/200% display scaling before proceeding to Phase 1.

### 0.8 Validation Checklist (Phase 0 Exit Criteria)

Do not proceed to Phase 1 until all of the following pass:

- [ ] Flutter view renders inside Qt widget hierarchy
- [ ] gRPC unary calls succeed from Flutter on Windows
- [ ] gRPC server-streaming receives and displays live data
- [ ] REST calls succeed via `dio`
- [ ] Keyboard input routes correctly into Flutter views
- [ ] Mouse/scroll input works inside the Flutter container
- [ ] App renders correctly at 100%, 150%, and 200% DPI
- [ ] Resize of the Qt window correctly reflows the Flutter container
- [ ] No crashes on show/hide of the Flutter container widget
- [ ] CI generates Dart protobuf stubs from `.proto` files automatically

---

## Phase 1 — Parallel Build, No Regressions

> Goal: New features go to Flutter only. Qt screens are untouched.

### Rules for this phase

1. **New features → Flutter only.** No new Qt screens or widgets.
2. **Qt screens → maintenance mode.** Bug fixes only, no enhancements.
3. **Design system first.** Build shared components before building screens.

### Design System Baseline

In `packages/design_system`, create before any screen work:

- `AppTheme` — colors, typography, spacing tokens matching Qt app's visual language
- `AppButton`, `AppTextField`, `AppDialog`, `AppDataTable`, `AppSidebar`
- Loading, error, and empty state widgets
- A `WidgetCatalog` screen (dev-only) that renders all components

### Navigation Routing (Qt → Flutter handoff)

Qt's navigation stack should be able to delegate to Flutter for migrated screens. Implement a simple string-based router contract:

```cpp
// Qt side — NavigationBridge.h
class NavigationBridge : public QObject {
    Q_OBJECT
public:
    void navigateTo(const QString& route, const QVariantMap& params);
signals:
    void routeRequested(const QString& route, const QVariantMap& params);
};
```

```dart
// Flutter side — listen via MethodChannel or shared memory IPC
// Use go_router for Flutter-side routing
final router = GoRouter(routes: [
  GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
  GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),
  // add migrated routes here
]);
```

Use a `MethodChannel` or a named pipe to pass navigation intent from Qt → Flutter when the user triggers a migrated screen.

---

## Phase 2 — Strangler Fig Migration

> Goal: Migrate screens in priority order. Each migrated screen removes a Qt dependency.

### Migration Priority Order

Migrate in this sequence to maximise early wins and minimise risk:

1. **High-traffic, low-complexity screens** — dashboards, status views, read-only data displays
2. **Real-time streaming screens** — gRPC streaming maps cleanly to `StreamProvider`
3. **Command/mutation screens** — forms that send gRPC mutations or REST POSTs
4. **Settings, preferences, about screens** — self-contained, low-risk
5. **Complex custom-rendered views** — leave last; assess FFI need case by case

### Per-Screen Migration Checklist

For each screen being migrated:

- [ ] Create a `packages/feature_<name>` package
- [ ] Identify all gRPC/REST calls the Qt screen makes
- [ ] Create Riverpod providers for each call/stream in `packages/core`
- [ ] Build the Flutter screen using design system components only
- [ ] Add the route to `go_router`
- [ ] Update `NavigationBridge` in Qt to delegate this route to Flutter
- [ ] Hide (do not delete yet) the Qt screen class
- [ ] Test: navigation, data loading, streaming, mutations, error states, DPI
- [ ] Delete Qt screen class after two sprint cycles with no regressions

### State Management Conventions

Enforce these patterns across all feature packages:

```dart
// Queries / streams — use StreamProvider or FutureProvider
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(orderServiceProvider).getOrders(GetOrdersRequest());
});

// Commands / mutations — use AsyncNotifier
class CreateOrderNotifier extends AsyncNotifier<void> {
  Future<void> create(CreateOrderRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(orderServiceProvider).createOrder(req),
    );
  }

  @override
  FutureOr<void> build() {}
}
final createOrderProvider =
    AsyncNotifierProvider<CreateOrderNotifier, void>(
        CreateOrderNotifier.new);
```

---

## Phase 3 — Shell Flip & Qt Retirement

> Trigger: Flutter covers ≥80% of screens and carries majority of active usage.

### Steps

1. **Audit remaining Qt screens.** Categorise: migrate now, wrap via FFI, or eliminate.
2. **Make Flutter the navigation owner.** Flutter's `go_router` drives all routing. Qt shell is demoted to a launch wrapper.
3. **Eliminate the `QTimer`-based message loop.** Replace with proper Win32 message pump integration or remove once Qt shell is retired.
4. **Drop Qt dependency.** Final executable is a standard `flutter build windows` output.
5. **Remove `FlutterContainer` and all embedding code.** No longer needed.

---

## Known Issues & Mitigations Reference

| Issue | Location | Mitigation |
|---|---|---|
| Keyboard input not reaching Flutter | `FlutterFocusFilter` | Install `QAbstractNativeEventFilter`, forward `WM_SETFOCUS` |
| Double DPI scaling | `main.cpp` | `Qt::AA_DisableHighDpiScaling` + `DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2` |
| Flutter HWND doesn't resize | `FlutterContainer::resizeEvent` | Manually resize `container_widget_` in `resizeEvent` override |
| Flutter message loop stalling | `QTimer` in `FlutterContainer` | Drive `FlutterDesktopEngineProcessMessages` on 16ms timer |
| gRPC stream not closing on widget dispose | Riverpod | Use `autoDispose` on all `StreamProvider`s |
| Proto stubs out of sync | CI | Add `protoc` generation step to CI pipeline, fail on dirty diff |

---

## File Layout Reference

```
project-root/
├── qt_app/                          # Existing Qt project
│   ├── FlutterContainer.h/.cpp      # NEW — embedding wrapper
│   ├── FlutterFocusFilter.h         # NEW — focus routing fix
│   ├── NavigationBridge.h/.cpp      # NEW — routing handoff
│   └── ... existing Qt files
│
├── flutter/
│   ├── app/                         # Flutter entry point
│   │   └── lib/main.dart
│   └── packages/
│       ├── core/                    # gRPC stubs, REST clients, providers
│       │   └── lib/src/
│       │       ├── proto/           # Generated protobuf Dart files
│       │       ├── grpc_client.dart
│       │       └── providers.dart
│       ├── design_system/           # Shared widgets and theme
│       │   └── lib/src/
│       │       ├── theme.dart
│       │       └── widgets/
│       └── feature_<name>/          # One per migrated screen group
│           └── lib/src/
│               ├── providers.dart
│               └── screens/
│
└── protos/                          # Shared .proto source files
    └── *.proto
```

---

## Dependencies Reference

**Flutter / Dart (`pubspec.yaml`)**:
```yaml
dependencies:
  grpc: ^3.2.4
  protobuf: ^3.1.0
  dio: ^5.4.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^13.0.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  protoc_plugin: ^21.1.2
```

**Qt (`CMakeLists.txt` additions)**:
```cmake
find_package(flutter_windows REQUIRED)
target_link_libraries(MyQtApp PRIVATE flutter_windows)
```

---

## Commands Cheat Sheet

```bash
# Generate Dart protobuf stubs
protoc --dart_out=grpc:flutter/packages/core/lib/src/proto \
       --proto_path=protos \
       service.proto

# Run code generation (Riverpod, etc.)
cd flutter/app && dart run build_runner build --delete-conflicting-outputs

# Build Flutter Windows release
cd flutter/app && flutter build windows --release

# Copy Flutter build artifacts next to Qt executable
# (required for embedding — flutter_windows.dll, flutter_assets/, icudtl.dat)
cp -r build/windows/runner/Release/* path/to/qt/output/
```

---

*These instructions are scoped to: Windows-only deployment, single-process embedding, gRPC + REST backend, Flutter Windows stable channel.*
