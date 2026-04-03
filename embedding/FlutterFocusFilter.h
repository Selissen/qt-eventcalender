#pragma once
#ifndef Q_OS_WASM

#include <QAbstractNativeEventFilter>
#include <windows.h>

class FlutterContainer;

/// Forwards WM_SETFOCUS to the Flutter child HWND when the Flutter view
/// is visible, preventing Qt from stealing keyboard focus away from Flutter.
class FlutterFocusFilter : public QAbstractNativeEventFilter {
public:
    explicit FlutterFocusFilter(FlutterContainer* container)
        : container_(container) {}

    bool nativeEventFilter(const QByteArray& eventType,
                           void* message,
                           qintptr* /*result*/) override;

private:
    FlutterContainer* container_;
};

#endif // Q_OS_WASM
