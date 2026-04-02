#pragma once
#ifndef Q_OS_WASM

#include <QWidget>
#include <QWindow>

// Flutter Windows Embedder public API.
// Headers live flat in the Flutter engine artifact cache (no flutter/ subdir).
// Include path is set via target_include_directories in CMakeLists.txt.
#include <flutter_windows.h>

/// Hosts a Flutter view inside a Qt widget hierarchy.
///
/// Usage:
///   FlutterContainer* c = new FlutterContainer(parentWidget);
///   c->initialize(assetsPath, icuDataPath);
///   c->show();
///
/// The FlutterContainer drives Flutter's message loop from Qt's event loop via
/// a QTimer ticking at ~60 fps.  Resize events are forwarded automatically.
class FlutterContainer : public QWidget {
    Q_OBJECT
public:
    explicit FlutterContainer(QWidget* parent = nullptr);
    ~FlutterContainer() override;

    /// Initialise the Flutter engine.
    /// @param assetsPath      Absolute path to the flutter_assets directory.
    /// @param icuDataPath     Absolute path to icudtl.dat.
    /// @param aotLibraryPath  Absolute path to app.so (required for release builds; empty for debug).
    /// @returns true on success, false if the engine or controller failed to create.
    bool initialize(const QString& assetsPath,
                    const QString& icuDataPath,
                    const QString& aotLibraryPath = {});

    /// Returns the raw Win32 HWND of the Flutter view (needed for focus routing).
    /// Returns nullptr before initialize() is called.
    HWND flutterHwnd() const;

protected:
    void resizeEvent(QResizeEvent* event) override;

private:
    FlutterDesktopEngineRef     engine_     = nullptr;
    FlutterDesktopViewControllerRef controller_ = nullptr;
    QWindow*  flutter_window_    = nullptr;
    QWidget*  container_widget_  = nullptr;
};

#endif // Q_OS_WASM
