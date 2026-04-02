#pragma once
#ifndef Q_OS_WASM

#include <QAbstractNativeEventFilter>
#include <windows.h>

/// Ensures keyboard focus is forwarded to the Flutter HWND when Qt receives
/// WM_SETFOCUS.  Without this, Qt intercepts focus and Flutter views become
/// unresponsive to keyboard input.
///
/// Install after FlutterContainer::initialize():
///   qApp->installNativeEventFilter(
///       new FlutterFocusFilter(container->flutterHwnd()));
class FlutterFocusFilter : public QAbstractNativeEventFilter {
public:
    explicit FlutterFocusFilter(HWND flutterHwnd)
        : flutter_hwnd_(flutterHwnd) {}

    bool nativeEventFilter(const QByteArray& eventType,
                           void* message,
                           qintptr* /*result*/) override
    {
        if (eventType == "windows_generic_MSG") {
            const auto* msg = static_cast<const MSG*>(message);
            if (msg->message == WM_SETFOCUS && flutter_hwnd_)
                SetFocus(flutter_hwnd_);
        }
        return false; // never consume the event
    }

private:
    HWND flutter_hwnd_;
};

#endif // Q_OS_WASM
