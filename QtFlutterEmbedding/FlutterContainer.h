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
    enum class State { Uninitialized, Initialized, Embedded };

    explicit FlutterContainer(QObject* parent = nullptr);
    ~FlutterContainer() override;

    State state() const { return state_; }

    /// Returns false (no-op) if already initialized.
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

signals:
    /// Emitted when initialize() fails, in addition to the qWarning() log.
    /// Connect to show a fallback UI or log to telemetry.
    void initializationFailed(const QString& reason);

private:
    FlutterDesktopEngineRef          engine_           = nullptr;
    FlutterDesktopViewControllerRef  controller_       = nullptr;
    QTimer*                          loop_timer_       = nullptr;
    bool                             embedded_visible_ = false;
    State                            state_            = State::Uninitialized;
};

#endif // Q_OS_WASM
