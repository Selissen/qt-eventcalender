#ifndef Q_OS_WASM

#include "FlutterView.h"
#include "NavigationBridge.h"

FlutterView::FlutterView(QQuickItem* parent)
    : QQuickItem(parent) {}

void FlutterView::setBridge(NavigationBridge* b)
{
    if (bridge_ == b)
        return;
    bridge_ = b;
    if (bridge_)
        bridge_->setFlutterView(this);
    emit bridgeChanged();
    syncRect();
}

void FlutterView::geometryChange(const QRectF& newGeom, const QRectF& oldGeom)
{
    QQuickItem::geometryChange(newGeom, oldGeom);
    syncRect();
}

void FlutterView::itemChange(ItemChange change, const ItemChangeData& value)
{
    QQuickItem::itemChange(change, value);
    if (change == ItemVisibleHasChanged && bridge_)
        bridge_->setFlutterVisible(value.boolValue);
}

void FlutterView::syncRect()
{
    if (!bridge_ || !window())
        return;
    // mapToScene gives item top-left in QQuickWindow logical coordinates.
    // With AA_DisableHighDpiScaling, logical == physical == HWND coordinates.
    const QPointF scenePos = mapToScene(QPointF(0, 0));
    bridge_->updateFlutterRect(
        qRound(scenePos.x()), qRound(scenePos.y()),
        qRound(width()),       qRound(height()));
}

#endif // Q_OS_WASM
