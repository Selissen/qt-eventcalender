#pragma once
#ifndef Q_OS_WASM

#include <QWidget>
#include <QWindow>
#include <flutter_windows.h>

/// Layout slot that hosts a single Flutter component inside a Qt widget hierarchy.
///
/// Qt's layout system drives geometry; the proxy relays size and position
/// changes to the Flutter HWND automatically.
///
/// Usage:
///   auto* proxy = new FlutterWidgetProxy(controller, parentWidget);
///   layout->addWidget(proxy, /*stretch=*/1);
///   // Call activate() once the proxy is visible in a layout:
///   proxy->activate();
///
/// The controller lifetime is owned by the caller (usually ComponentEngineFactory
/// or a Qt screen), NOT by the proxy. Destroy the controller after the proxy.
class FlutterWidgetProxy : public QWidget {
    Q_OBJECT
public:
    explicit FlutterWidgetProxy(FlutterDesktopViewControllerRef controller,
                                QWidget* parent = nullptr);
    ~FlutterWidgetProxy() override;

    /// Reparent the Flutter HWND into this widget's HWND.
    /// Call once after the proxy has been added to a layout and shown.
    void activate();

protected:
    void resizeEvent(QResizeEvent* event) override;
    void moveEvent(QMoveEvent* event) override;
    void showEvent(QShowEvent* event) override;
    void hideEvent(QHideEvent* event) override;

private:
    void syncGeometry();

    FlutterDesktopViewControllerRef controller_;
    QWindow*  flutter_window_ = nullptr;
    QWidget*  container_      = nullptr;
};

#endif // Q_OS_WASM
