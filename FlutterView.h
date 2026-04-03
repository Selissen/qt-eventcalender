#pragma once
#ifndef Q_OS_WASM

#include <QQuickItem>
#include "NavigationBridge.h"

/// A QQuickItem that mirrors its QML geometry to the embedded Flutter HWND.
///
/// Place this in QML using normal anchors/layouts; the item's geometryChange()
/// and itemChange(Visible) keep the Win32 child window in sync automatically.
///
///   FlutterView {
///       anchors.fill: parent   // fills the ApplicationWindow content area
///       bridge: navBridge
///   }
class FlutterView : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(NavigationBridge* bridge READ bridge WRITE setBridge NOTIFY bridgeChanged)
public:
    explicit FlutterView(QQuickItem* parent = nullptr);

    NavigationBridge* bridge() const { return bridge_; }
    void setBridge(NavigationBridge* b);

signals:
    void bridgeChanged();

protected:
    void geometryChange(const QRectF& newGeom, const QRectF& oldGeom) override;
    void itemChange(ItemChange change, const ItemChangeData& value) override;

private:
    void syncRect();

    NavigationBridge* bridge_ = nullptr;
};

#endif // Q_OS_WASM
