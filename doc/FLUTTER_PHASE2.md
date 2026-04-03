# Qt → Flutter Migration: Phase 2 Instructions
## Component-Level Embedding & Screen Migration

**Prerequisites**: Phase 0 (embedding foundation, gRPC wiring, DPI/focus fixes) and Phase 1 (design system, new features in Flutter, navigation bridge) are complete.

---

## Current State Assumptions

- Flutter engine is embedded in Qt shell via `FlutterContainer` (single HWND)
- `NavigationBridge` routes full screens from Qt → Flutter
- gRPC/REST providers are wired in `packages/core`
- Design system components exist in `packages/design_system`
- `go_router` is configured for migrated full screens

---

## Part 1 — Component-Level Embedding

> Goal: Embed individual Flutter components (maps, charts, custom widgets) inside existing Qt screens — without migrating the full screen yet.

This is distinct from full-screen migration. The Qt screen remains the owner. Flutter renders only a bounded region within it.

---

### 1.1 FlutterWidgetProxy — Layout Placeholder

Create a `QWidget` subclass that acts as a layout slot for a Flutter component. Qt's layout system drives geometry; the proxy relays it to the Flutter HWND.

**FlutterWidgetProxy.h**:
```cpp
#pragma once
#include <QWidget>
#include <QWindow>
#include <flutter/flutter_windows.h>

class FlutterWidgetProxy : public QWidget {
    Q_OBJECT
public:
    explicit FlutterWidgetProxy(
        FlutterDesktopViewControllerRef controller,
        QWidget* parent = nullptr);
    ~FlutterWidgetProxy();

    // Call after construction to activate the Flutter view
    void activate();

protected:
    void resizeEvent(QResizeEvent* event) override;
    void moveEvent(QMoveEvent* event) override;
    void showEvent(QShowEvent* event) override;
    void hideEvent(QHideEvent* event) override;

private:
    void syncGeometry();

    FlutterDesktopViewControllerRef controller_;
    QWindow* flutter_window_  = nullptr;
    QWidget* container_       = nullptr;
};
```

**FlutterWidgetProxy.cpp**:
```cpp
#include "FlutterWidgetProxy.h"
#include <QResizeEvent>
#include <windows.h>

FlutterWidgetProxy::FlutterWidgetProxy(
    FlutterDesktopViewControllerRef controller,
    QWidget* parent)
    : QWidget(parent), controller_(controller)
{
    setAttribute(Qt::WA_TranslucentBackground);
    setAutoFillBackground(false);
}

void FlutterWidgetProxy::activate() {
    HWND hwnd = FlutterDesktopViewGetHWND(
        FlutterDesktopViewControllerGetView(controller_));

    // Allow sibling Qt controls to render without clipping issues
    SetWindowLong(hwnd, GWL_STYLE,
        GetWindowLong(hwnd, GWL_STYLE) | WS_CLIPSIBLINGS);

    flutter_window_ = QWindow::fromWinId((WId)hwnd);
    container_ = QWidget::createWindowContainer(flutter_window_, this);
    container_->setGeometry(0, 0, width(), height());
}

void FlutterWidgetProxy::syncGeometry() {
    if (container_)
        container_->setGeometry(0, 0, width(), height());
}

void FlutterWidgetProxy::resizeEvent(QResizeEvent* e) {
    QWidget::resizeEvent(e);
    syncGeometry();
}

void FlutterWidgetProxy::moveEvent(QMoveEvent* e) {
    QWidget::moveEvent(e);
    syncGeometry();
}

void FlutterWidgetProxy::showEvent(QShowEvent* e) {
    QWidget::showEvent(e);
    if (container_) container_->show();
}

void FlutterWidgetProxy::hideEvent(QHideEvent* e) {
    QWidget::hideEvent(e);
    if (container_) container_->hide();
}

FlutterWidgetProxy::~FlutterWidgetProxy() {
    // Controller lifetime is managed by the owning screen, not the proxy
}
```

Use in any Qt screen layout exactly like a native widget:

```cpp
auto* layout = new QVBoxLayout(this);
layout->addWidget(new QLabel("Live Map"));
layout->addWidget(new FlutterWidgetProxy(map_controller_), 1); // stretch=1
layout->addWidget(qt_status_bar_);
```

---

### 1.2 Engine Strategy Per Screen — One vs Two Engines

When a single Qt screen needs more than one Flutter component, choose:

**Option A — Separate engine per component**
- Simple, fully isolated
- ~20–30MB RAM overhead per additional engine
- Use when components are truly independent with no shared state

```cpp
auto* map_proxy   = new FlutterWidgetProxy(createController("map_assets"),   this);
auto* chart_proxy = new FlutterWidgetProxy(createController("chart_assets"), this);
```

**Option B — Single engine, route per region** (recommended for same-screen components)
- One engine, multiple view controllers
- Flutter internally renders different components per controller via initial route
- Shared Riverpod state, shared gRPC connections

Pass the component route as a Dart define at engine creation:

```cpp
// ComponentEngineFactory.h / .cpp
FlutterDesktopEngineRef ComponentEngineFactory::createEngine(
    const QString& assetsPath,
    const QString& route)
{
    FlutterDesktopEngineProperties props = {};
    props.assets_path = assetsPath.toStdWString().c_str();
    props.icu_data_path = L"icudtl.dat";

    // Pass route to Flutter via dart-define
    std::string define = "--dart-define=COMPONENT_ROUTE=" + route.toStdString();
    const char* args[] = { define.c_str() };
    props.dart_entrypoint_argv = args;
    props.dart_entrypoint_argc = 1;

    return FlutterDesktopEngineCreate(&props);
}
```

```dart
// Flutter side — main.dart
void main() {
  const route = String.fromEnvironment(
    'COMPONENT_ROUTE',
    defaultValue: '/map',
  );
  runApp(ProviderScope(child: ComponentRouter(initialRoute: route)));
}

class ComponentRouter extends StatelessWidget {
  final String initialRoute;
  const ComponentRouter({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,    // from packages/design_system
      home: switch (initialRoute) {
        '/map'        => const MapComponent(),
        '/chart'      => const ChartComponent(),
        '/data-table' => const DataTableComponent(),
        _             => const SizedBox.shrink(),
      },
    );
  }
}
```

---

### 1.3 Qt ↔ Flutter Communication (MethodChannel Bridge)

Each embedded component communicates with its Qt host screen via a named `MethodChannel`. Use a consistent naming convention:

```
com.<yourapp>/<component-name>
```

**Qt → Flutter (push state into component)**:

```cpp
// ComponentBridge.h
#pragma once
#include <QObject>
#include <QJsonObject>
#include <flutter/flutter_windows.h>

class ComponentBridge : public QObject {
    Q_OBJECT
public:
    explicit ComponentBridge(
        FlutterDesktopEngineRef engine,
        const QString& channel,
        QObject* parent = nullptr);

    void send(const QString& method, const QJsonObject& args = {});

signals:
    void messageReceived(const QString& method, const QJsonObject& args);

private:
    static void onMessage(
        FlutterDesktopMessengerRef messenger,
        const FlutterDesktopMessage* message,
        void* user_data);

    FlutterDesktopMessengerRef messenger_;
    std::string channel_;
};
```

```cpp
// ComponentBridge.cpp
ComponentBridge::ComponentBridge(
    FlutterDesktopEngineRef engine,
    const QString& channel,
    QObject* parent)
    : QObject(parent),
      messenger_(FlutterDesktopEngineGetMessenger(engine)),
      channel_(channel.toStdString())
{
    FlutterDesktopMessengerSetCallback(
        messenger_, channel_.c_str(), onMessage, this);
}

void ComponentBridge::send(const QString& method, const QJsonObject& args) {
    QJsonObject envelope;
    envelope["method"] = method;
    envelope["args"]   = args;
    QByteArray data = QJsonDocument(envelope).toJson(QJsonDocument::Compact);

    FlutterDesktopMessengerSend(
        messenger_,
        channel_.c_str(),
        reinterpret_cast<const uint8_t*>(data.constData()),
        static_cast<size_t>(data.size()));
}

void ComponentBridge::onMessage(
    FlutterDesktopMessengerRef,
    const FlutterDesktopMessage* message,
    void* user_data)
{
    auto* self = static_cast<ComponentBridge*>(user_data);
    QJsonDocument doc = QJsonDocument::fromJson(
        QByteArray(reinterpret_cast<const char*>(message->message),
                   static_cast<int>(message->message_size)));
    QJsonObject obj = doc.object();
    emit self->messageReceived(obj["method"].toString(), obj["args"].toObject());
}
```

**Usage in a Qt screen**:

```cpp
// In a Qt screen that hosts a map component
map_bridge_ = new ComponentBridge(engine_, "com.yourapp/map", this);

// Push data into Flutter map
map_bridge_->send("setLocation", {{"lat", 51.5074}, {"lng", -0.1278}, {"zoom", 12}});

// Receive events from Flutter map
connect(map_bridge_, &ComponentBridge::messageReceived,
    [this](const QString& method, const QJsonObject& args) {
        if (method == "pinTapped") {
            onMapPinTapped(args["pinId"].toString());
        }
    });
```

**Flutter component side**:

```dart
// map_component.dart
class MapComponent extends ConsumerStatefulWidget {
  const MapComponent({super.key});
  @override
  ConsumerState<MapComponent> createState() => _MapComponentState();
}

class _MapComponentState extends ConsumerState<MapComponent> {
  static const _channel = MethodChannel('com.yourapp/map');
  LatLng _center = const LatLng(0, 0);
  double _zoom = 10;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'setLocation':
        setState(() {
          _center = LatLng(
            call.arguments['lat'] as double,
            call.arguments['lng'] as double,
          );
          _zoom = (call.arguments['zoom'] as num).toDouble();
        });
    }
  }

  void _onPinTapped(String pinId) {
    _channel.invokeMethod('pinTapped', {'pinId': pinId});
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(initialCenter: _center, initialZoom: _zoom),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        // marker layer with _onPinTapped callback
      ],
    );
  }
}
```

---

### 1.4 Map Component — Package Choice

Use `flutter_map` (OpenStreetMap-based), not `google_maps_flutter`:

| | `flutter_map` | `google_maps_flutter` |
|---|---|---|
| Windows support | ✅ Full | ⚠️ Experimental |
| Embedding compatible | ✅ Dart-native renderer | ❌ Creates its own child HWND — conflicts with Qt embedding |
| Tile source | OpenStreetMap or custom | Google Maps only |
| Offline tiles | ✅ Supported | ❌ Not supported |

```yaml
# packages/feature_map/pubspec.yaml
dependencies:
  flutter_map: ^6.1.0
  latlong2: ^0.9.1
```

---

### 1.5 Z-Order & Rendering Issues

Components embedded at sub-screen level introduce Win32 z-order conflicts. Apply these fixes proactively:

**Qt tooltips and dropdowns rendering under Flutter HWND**

Qt popups that are children of the main window will render below the Flutter HWND. Force them to be top-level:

```cpp
// Apply to any QMenu, QToolTip, or QComboBox popup on screens with embedded Flutter
my_combo_box_->setWindowFlags(Qt::Popup | Qt::FramelessWindowHint);
```

**Flutter background covering Qt chrome**

Flutter renders opaque white by default. Set the background transparent if the component doesn't fill its entire bounds:

```cpp
// After creating the view controller
FlutterDesktopViewControllerSetBackgroundColor(controller_, 0x00000000);
```

```dart
// Flutter side — ensure root widget is transparent where needed
MaterialApp(
  theme: ThemeData(scaffoldBackgroundColor: Colors.transparent),
  home: MapComponent(),
)
```

**Scroll events not crossing the HWND boundary**

Mouse wheel events stop at the Flutter HWND edge and don't propagate back to Qt. Install a low-level mouse hook to forward them:

```cpp
// In FlutterWidgetProxy or a shared hook manager
static HHOOK scroll_hook_ = nullptr;

static LRESULT CALLBACK scrollHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0 && wParam == WM_MOUSEWHEEL) {
        auto* info = reinterpret_cast<MSLLHOOKSTRUCT*>(lParam);
        HWND target = WindowFromPoint(info->pt);
        // If scroll is over Qt content, forward to Qt's window
        PostMessage(target, WM_MOUSEWHEEL,
                    MAKEWPARAM(0, GET_WHEEL_DELTA_WPARAM(info->mouseData)),
                    MAKELPARAM(info->pt.x, info->pt.y));
    }
    return CallNextHookEx(scroll_hook_, nCode, wParam, lParam);
}

void installScrollHook() {
    scroll_hook_ = SetWindowsHookEx(
        WH_MOUSE_LL, scrollHookProc, nullptr, 0);
}
```

---

### 1.6 Component Embedding Checklist

Apply before shipping any embedded Flutter component to a Qt screen:

- [ ] `FlutterWidgetProxy` activates after Qt layout is established (`showEvent`)
- [ ] Component resizes correctly when Qt window is resized
- [ ] Component hides/shows correctly when Qt tab or panel is toggled
- [ ] MethodChannel sends data correctly Qt → Flutter
- [ ] MethodChannel receives events correctly Flutter → Qt
- [ ] No z-order conflicts with Qt tooltips, menus, or dropdowns on the same screen
- [ ] Background transparency correct (opaque or transparent, as designed)
- [ ] Scroll events behave correctly at the HWND boundary
- [ ] DPI rendering correct at 100%, 150%, 200%
- [ ] No memory leaks on repeated show/hide cycles (check with Task Manager over 10+ cycles)
- [ ] Engine and view controller destroyed correctly when parent Qt screen is closed

---

## Part 2 — Screen Migration (Strangler Fig Continues)

> Goal: Migrate full screens to Flutter in priority order. Each migration retires a Qt screen class.

---

### 2.1 Migration Priority Order

```
Tier 1 — Migrate first (low complexity, high traffic)
  - Dashboards and status views
  - Read-only data displays
  - Settings and preferences screens
  - About / help screens

Tier 2 — Migrate next (moderate complexity)
  - Real-time streaming screens     ← gRPC StreamProvider maps cleanly here
  - Command/mutation screens        ← forms that call gRPC mutations or REST POSTs
  - List + detail screen pairs

Tier 3 — Migrate last (highest complexity)
  - Screens with custom OpenGL or QPainter rendering
  - Screens with complex drag-and-drop
  - Screens requiring Windows shell integration (file dialogs, tray, notifications)
  - Any screen currently hosting embedded Flutter components
    (migrate the shell last, after components are already Flutter-native)
```

---

### 2.2 Per-Screen Migration Procedure

Follow this sequence for every screen:

**Step 1 — Audit the Qt screen**

Before writing any Flutter code, document:
- All gRPC/REST calls the screen makes (method names, request/response types)
- All signals/slots the screen emits or listens to
- Any platform APIs used (file system, clipboard, Windows shell)
- Any custom painting (`QPainter`, `QOpenGLWidget`)

**Step 2 — Create the feature package**

```bash
cd flutter/packages
flutter create --template=package feature_<screen_name>
```

Structure:
```
packages/feature_<screen_name>/
  lib/
    src/
      providers.dart    # Riverpod providers for this screen's data
      screens/
        <screen>_screen.dart
      widgets/          # Screen-local widgets (not in design_system)
  test/
```

**Step 3 — Wire providers in `packages/core`**

Add any new gRPC calls or streams to `packages/core`. Do not put gRPC stubs directly in feature packages.

```dart
// packages/core/lib/src/providers/orders_provider.dart
final ordersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(orderServiceStubProvider).watchOrders(WatchOrdersRequest());
});

final submitOrderProvider =
    AsyncNotifierProvider<SubmitOrderNotifier, void>(SubmitOrderNotifier.new);

class SubmitOrderNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(Order order) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(orderServiceStubProvider).createOrder(
              CreateOrderRequest(order: order),
            ));
  }
}
```

**Step 4 — Build the Flutter screen**

- Use only `packages/design_system` components — no raw Material widgets on visible surfaces
- All data via Riverpod providers only — no direct gRPC calls inside widgets
- Handle all three states explicitly: loading, error, data
- Streaming screens use `StreamProvider` + `AsyncValue.when`

```dart
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersStreamProvider);
    return AppScaffold(
      title: 'Orders',
      body: orders.when(
        data: (list) => OrdersTable(orders: list),
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorView(error: e),
      ),
    );
  }
}
```

**Step 5 — Register the route**

```dart
// app/lib/router.dart
GoRoute(
  path: '/orders',
  builder: (context, state) => const OrdersScreen(),
),
```

**Step 6 — Update NavigationBridge in Qt**

```cpp
// NavigationBridge.cpp
void NavigationBridge::navigateTo(const QString& route,
                                   const QVariantMap& params)
{
    // Routes handled by Flutter
    static const QSet<QString> flutter_routes = {
        "/settings", "/dashboard", "/orders",  // add new route here
    };

    if (flutter_routes.contains(route)) {
        emit routeRequestedInFlutter(route, params);
    } else {
        emit routeRequestedInQt(route, params);
    }
}
```

**Step 7 — Shadow and verify**

- Keep the Qt screen class but stop routing users to it
- Run Flutter and Qt screens in parallel for one sprint cycle
- Verify: all data loads, streaming works, mutations succeed, error states show correctly

**Step 8 — Delete the Qt screen**

After one sprint cycle with no regressions:
```
- Delete the Qt screen .h and .cpp files
- Remove it from Qt's navigation/menu registration
- Remove it from CMakeLists.txt
```

Do not keep dead Qt code. Deletion is the completion signal.

---

### 2.3 Streaming Screen Pattern

Screens showing real-time gRPC data are the highest-value migrations. Flutter handles these better than Qt — no manual thread marshalling, no signal wiring.

Standard pattern for any streaming screen:

```dart
// Provider — autoDispose ensures stream closes when screen is left
final deviceStatusProvider =
    StreamProvider.autoDispose<DeviceStatus>((ref) {
  final stub = ref.watch(deviceServiceStubProvider);
  return stub.watchStatus(WatchStatusRequest(deviceId: 'device-1'))
      .handleError((e) => throw GrpcError.fromError(e));
});

// Screen
class DeviceStatusScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(deviceStatusProvider);
    return status.when(
      data: (s) => DeviceStatusPanel(status: s),
      loading: () => const AppLoadingSpinner(),
      error: (e, _) => AppErrorView(error: e, onRetry: () =>
          ref.invalidate(deviceStatusProvider)),
    );
  }
}
```

Always use `autoDispose` on streaming providers — without it, the gRPC stream stays open after the user navigates away.

---

### 2.4 Screens with Windows Platform APIs

Some Qt screens may use Windows APIs with no direct Flutter equivalent. Handle case by case:

| Qt feature | Flutter equivalent | Notes |
|---|---|---|
| `QFileDialog` | `file_picker` package | Works on Windows, well-maintained |
| `QClipboard` | `flutter/services` `Clipboard` | Built-in |
| `QSystemTrayIcon` | `tray_manager` package | Windows support stable |
| `QDesktopServices::openUrl` | `url_launcher` package | Works on Windows |
| `QMessageBox` | `AppDialog` from design_system | Build in design system, not ad-hoc |
| Custom `QPainter` rendering | `CustomPainter` in Flutter | Port drawing logic; API is equivalent |
| `QOpenGLWidget` | `flutter_gl` or keep in Qt via FFI | Complex — assess per screen; defer to Tier 3 |

---

## Part 3 — Phase 2 Exit Criteria

Before declaring Phase 2 complete and beginning Phase 3 (shell flip):

### Coverage
- [ ] ≥80% of screens migrated to Flutter
- [ ] All Tier 1 screens deleted from Qt
- [ ] All Tier 2 screens deleted from Qt
- [ ] New features have shipped exclusively in Flutter for at least 2 months

### Stability
- [ ] No open Flutter embedding bugs (z-order, focus, DPI, resize)
- [ ] All gRPC streaming providers use `autoDispose` — no stream leaks
- [ ] Memory profile stable over 4+ hours of use (no engine leak on navigation)
- [ ] App runs correctly on Windows 10 and Windows 11

### Architecture
- [ ] No gRPC stubs imported directly in feature packages — all via `packages/core`
- [ ] No raw Material widgets on visible surfaces — all via `packages/design_system`
- [ ] `NavigationBridge` routes majority of navigation to Flutter
- [ ] Qt screen classes for all migrated screens have been deleted (not commented out)

### Remaining Qt inventory
- [ ] Document every remaining Qt screen with: complexity rating, platform API dependencies, estimated migration effort
- [ ] Decision recorded for each: migrate in Phase 3, wrap via FFI, or eliminate

---

## File Layout Additions (Phase 2)

```
flutter/packages/
├── core/
│   └── lib/src/
│       ├── proto/                    # Generated stubs (unchanged)
│       └── providers/               # NEW — one file per service domain
│           ├── orders_provider.dart
│           ├── device_provider.dart
│           └── ...
│
├── design_system/                    # Unchanged — additions only
│
├── feature_dashboard/               # Example migrated screen packages
├── feature_orders/
├── feature_device_status/
└── feature_<n>/
```

```
qt_app/
├── FlutterContainer.h/.cpp          # Unchanged
├── FlutterWidgetProxy.h/.cpp        # NEW — component embedding
├── ComponentBridge.h/.cpp           # NEW — MethodChannel bridge
├── ComponentEngineFactory.h/.cpp    # NEW — engine-per-component factory
├── NavigationBridge.h/.cpp          # MODIFIED — growing flutter_routes set
└── screens/                         # Shrinking — deleted as screens migrate
```

---

## Commands Reference

```bash
# Add a new feature package
cd flutter/packages && flutter create --template=package feature_<name>

# Add dependency from feature package to core
cd flutter/packages/feature_<name>
flutter pub add --path ../core

# Run build_runner after adding providers
cd flutter/app && dart run build_runner build --delete-conflicting-outputs

# Check for stream/memory issues (run then watch Task Manager for 10 min)
flutter run -d windows --profile

# Regenerate gRPC stubs after .proto changes
protoc --dart_out=grpc:flutter/packages/core/lib/src/proto \
       --proto_path=protos \
       *.proto
```

---

*Prerequisite: CLAUDE.md Phase 0 and Phase 1 complete. This file covers component-level embedding and full screen migration. Phase 3 (shell flip, Qt retirement) instructions are issued separately.*
