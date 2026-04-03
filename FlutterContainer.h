#pragma once
#ifndef Q_OS_WASM

#include <QObject>
#include <QTimer>
#include <windows.h>
#include <flutter_windows.h>
#include <flutter_messenger.h>

/// Manages the Flutter Windows engine and embeds its view into a native
/// Win32 parent window.
///
/// Lifecycle:
///   1. Construct and call initialize() with asset/icu/aot paths.
///   2. Call embedInto(parentHwnd) to reparent Flutter's HWND as a child of
///      an existing Win32 window (e.g. the QQuickWindow). Starts hidden.
///   3. Call moveToRect(x, y, w, h) to position/size the HWND — driven by
///      FlutterView's geometryChange() so QML anchors control the layout.
///   4. Call showEmbedded() / hideEmbedded() to toggle visibility.
///   5. Use messenger() + FlutterDesktopMessengerSend for channel messages.
class FlutterContainer : public QObject {
    Q_OBJECT
public:
    explicit FlutterContainer(QObject* parent = nullptr);
    ~FlutterContainer() override;

    bool initialize(const QString& assetsPath,
                    const QString& icuDataPath,
                    const QString& aotLibraryPath = {});

    /// Reparent the Flutter view HWND as a Win32 child of parentHwnd.
    /// Position and size are managed via moveToRect(); starts hidden.
    bool embedInto(HWND parentHwnd);

    /// Move and resize the Flutter HWND to the given rect (physical pixels,
    /// relative to the parent window). Called by FlutterView on geometry change.
    void moveToRect(int x, int y, int w, int h);

    void showEmbedded();
    void hideEmbedded();
    bool isEmbeddedVisible() const { return embedded_visible_; }

    HWND flutterHwnd() const;

    /// Messenger for sending to Flutter channels (e.g. FlutterDesktopMessengerSend).
    FlutterDesktopMessengerRef messenger() const;

private:
    FlutterDesktopEngineRef          engine_           = nullptr;
    FlutterDesktopViewControllerRef  controller_       = nullptr;
    QTimer*                          loop_timer_       = nullptr;
    bool                             embedded_visible_ = false;
};

#endif // Q_OS_WASM
