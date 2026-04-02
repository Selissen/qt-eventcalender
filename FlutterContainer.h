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
///   2. Call embedInto(parentHwnd, w, h) to reparent Flutter's HWND as a
///      child of an existing Win32 window (e.g. the QQuickWindow).
///   3. Call showEmbedded() / hideEmbedded() to toggle visibility.
///   4. Call resizeEmbedded(w, h) whenever the parent window resizes.
///   5. Use messenger() + FlutterDesktopMessengerSend to send messages to
///      Flutter (e.g. navigation channel).
class FlutterContainer : public QObject {
    Q_OBJECT
public:
    explicit FlutterContainer(QObject* parent = nullptr);
    ~FlutterContainer() override;

    bool initialize(const QString& assetsPath,
                    const QString& icuDataPath,
                    const QString& aotLibraryPath = {});

    /// Reparent the Flutter view HWND as a Win32 child of parentHwnd, sized
    /// to (w, h). Starts hidden — call showEmbedded() to make it visible.
    bool embedInto(HWND parentHwnd, int w, int h);

    void showEmbedded();
    void hideEmbedded();
    bool isEmbeddedVisible() const { return embedded_visible_; }

    void resizeEmbedded(int w, int h);

    HWND flutterHwnd() const;

    /// Messenger for sending to Flutter channels (e.g. FlutterDesktopMessengerSend).
    FlutterDesktopMessengerRef messenger() const;

private:
    FlutterDesktopEngineRef          engine_     = nullptr;
    FlutterDesktopViewControllerRef  controller_ = nullptr;
    QTimer*                          loop_timer_ = nullptr;
    bool                             embedded_visible_ = false;
};

#endif // Q_OS_WASM
