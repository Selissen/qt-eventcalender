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
/// Typical setup in main():
///   ComponentEngineFactory::setArtifactsDir(exeDir);
///
/// Then per component (or from QML via FlutterComponentView.artifactsDir):
///   auto* ctrl = ComponentEngineFactory::createController("mapComponentMain");
class ComponentEngineFactory {
public:
    ComponentEngineFactory() = delete;

    /// Set the process-wide default directory that contains flutter_assets/,
    /// icudtl.dat, and app.so.  Call once from main() before any component is
    /// shown.  Thread safety: must be called from the main thread before any
    /// engine is created.
    static void setArtifactsDir(const QString& path);

    /// Returns the configured artifacts directory, or
    /// QCoreApplication::applicationDirPath() when none has been set.
    static QString artifactsDir();

    /// Convenience overload: derives assetsPath / icuDataPath / aotPath from
    /// artifactsDir() and forwards to the full overload.
    ///
    /// Pass a non-empty \a instanceId to scope the component's message channel
    /// and Dart entry-point arguments to a unique instance (e.g. "planning" or
    /// "overview").  The engine receives \c --instanceId=<id> via
    /// \c dart_entrypoint_argv so the Dart side can construct a matching channel
    /// name.  Two components with different instanceIds on the same entrypoint
    /// are fully independent.  When empty (default), no argv is added and the
    /// channel is used as-is — existing callers are unaffected.
    static FlutterDesktopViewControllerRef createController(
        const QString& entrypoint,
        const QString& instanceId = {},
        int initialWidth  = 400,
        int initialHeight = 300);

    /// Full overload: explicit paths for all three artifacts.  Use this when a
    /// specific component needs artifacts from a non-default location.
    static FlutterDesktopViewControllerRef createController(
        const QString& assetsPath,
        const QString& icuDataPath,
        const QString& aotLibraryPath,
        const QString& entrypoint,
        const QString& instanceId = {},
        int initialWidth  = 400,
        int initialHeight = 300);
};

#endif // Q_OS_WASM
