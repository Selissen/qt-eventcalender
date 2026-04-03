#pragma once
#ifndef Q_OS_WASM

#include <QString>
#include <QVector>
#include <flutter_windows.h>

/// Creates Flutter engines and view controllers for component-level embedding.
///
/// Each call to createController() returns a new view controller backed by a
/// dedicated engine.  Pass the Dart @pragma('vm:entry-point') function name as
/// `entrypoint`; the engine will call that function instead of main().
///
/// Ownership: the returned controller (and its engine) must be destroyed via
/// FlutterDesktopViewControllerDestroy() when the host is closed.
///
/// Example:
///   auto* ctrl = ComponentEngineFactory::createController(
///       exeDir + "/flutter_assets",
///       exeDir + "/icudtl.dat",
///       exeDir + "/app.so",
///       "mapComponentMain");
class ComponentEngineFactory {
public:
    ComponentEngineFactory() = delete;

    static FlutterDesktopViewControllerRef createController(
        const QString& assetsPath,
        const QString& icuDataPath,
        const QString& aotLibraryPath,
        const QString& entrypoint,      ///< Dart function name, e.g. "mapComponentMain"
        int initialWidth  = 400,
        int initialHeight = 300);
};

#endif // Q_OS_WASM
