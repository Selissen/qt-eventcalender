#ifndef Q_OS_WASM

#include "FlutterView.h"
#include "NavigationBridge.h"

#include <QQuickWindow>

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
    // mapToScene() returns logical pixel coordinates; Win32 MoveWindow needs
    // physical pixels.  Multiply by devicePixelRatio() to convert.
    const QPointF scenePos = mapToScene(QPointF(0, 0));
    const qreal   dpr      = window()->devicePixelRatio();
    bridge_->updateFlutterRect(
        qRound(scenePos.x() * dpr), qRound(scenePos.y() * dpr),
        qRound(width()       * dpr), qRound(height()      * dpr));
}

#endif // Q_OS_WASM
