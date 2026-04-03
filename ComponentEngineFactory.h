#pragma once
#ifndef Q_OS_WASM

#include <QString>
#include <QVector>
#include <flutter_windows.h>

/// Creates Flutter engines and view controllers for component-level embedding.
///
/// Each call to createController() returns a new view controller backed by
/// a dedicated engine.  The engine receives COMPONENT_ROUTE via --dart-define
/// so the Flutter app can render the correct component without a full navigator.
///
/// Ownership: the returned controller (and its engine) must be destroyed by
/// the caller via FlutterDesktopViewControllerDestroy() when the host Qt screen
/// is closed.  This also destroys the backing engine.
///
/// Example:
///   auto* ctrl = ComponentEngineFactory::createController(
///       exeDir + "/flutter_assets",
///       exeDir + "/icudtl.dat",
///       exeDir + "/app.so",
///       "/map");
///   auto* proxy = new FlutterWidgetProxy(ctrl, this);
///   layout->addWidget(proxy);
///   proxy->activate();
class ComponentEngineFactory {
public:
    ComponentEngineFactory() = delete;

    static FlutterDesktopViewControllerRef createController(
        const QString& assetsPath,
        const QString& icuDataPath,
        const QString& aotLibraryPath,
        const QString& componentRoute,
        int initialWidth  = 400,
        int initialHeight = 300);
};

#endif // Q_OS_WASM
