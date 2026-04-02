#ifndef Q_OS_WASM

#include "FlutterFocusFilter.h"
#include "FlutterContainer.h"

bool FlutterFocusFilter::nativeEventFilter(const QByteArray& eventType,
                                           void* message,
                                           qintptr*)
{
    if (eventType != "windows_generic_MSG")
        return false;

    const auto* msg = static_cast<const MSG*>(message);
    if (msg->message == WM_SETFOCUS
            && container_
            && container_->isEmbeddedVisible()) {
        HWND hwnd = container_->flutterHwnd();
        if (hwnd)
            ::SetFocus(hwnd);
    }
    return false;
}

#endif // Q_OS_WASM
