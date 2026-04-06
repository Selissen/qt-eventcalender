#ifndef Q_OS_WASM

#include "FlutterMapItem.h"
#include "flutter_constants.h"

#include "../QtFlutterEmbedding/FlutterComponentView.h"

#include <QJsonArray>
#include <QJsonObject>
#include <QVariantMap>

FlutterMapItem::FlutterMapItem(QQuickItem* parent)
    : QQuickItem(parent) {}

void FlutterMapItem::setInstanceId(const QString& v)
{
    if (instanceId_ == v) return;
    instanceId_ = v;
    emit instanceIdChanged();
}

// ── Engine lifecycle ──────────────────────────────────────────────────────────

void FlutterMapItem::ensureComponent()
{
    if (component_) return;

    component_ = new FlutterComponentView(this);
    component_->setEntrypoint(QStringLiteral("mapComponentMain"));
    component_->setChannel(QLatin1String(FlutterChannels::kMap));
    component_->setInstanceId(instanceId_);

    // Mirror our geometry into the inner component.
    component_->setX(0);
    component_->setY(0);
    component_->setWidth(width());
    component_->setHeight(height());
    component_->setVisible(isVisible());

    // Forward engine errors up to QML.
    connect(component_, &FlutterComponentView::engineError,
            this, &FlutterMapItem::engineError);

    // Flush buffered routes once Flutter's message handler is registered.
    connect(component_, &FlutterComponentView::readyChanged, this, [this]() {
        if (component_->ready()) flushPendingRoutes();
    });

    // Translate raw JSON messages into typed domain signals.
    connect(component_, &FlutterComponentView::messageReceived,
            this, [this](const QString& method, const QVariantMap& args) {
        if (method == QLatin1String("toggleRoute"))
            emit routeToggled(args.value(QStringLiteral("id")).toInt());
    });
}

// ── Public API ────────────────────────────────────────────────────────────────

void FlutterMapItem::updateRoutes(const QVariantList& allRoutes,
                                  const QVariantList& selectedIds)
{
    pendingAllRoutes_   = allRoutes;
    pendingSelectedIds_ = selectedIds;
    pendingDirty_       = true;
    flushPendingRoutes();
}

void FlutterMapItem::flushPendingRoutes()
{
    if (!pendingDirty_ || !component_ || !component_->ready())
        return;

    QJsonArray routesArr;
    for (const QVariant& v : std::as_const(pendingAllRoutes_)) {
        const QVariantMap m = v.toMap();
        QJsonObject r;
        r[QStringLiteral("id")]   = m.value(QStringLiteral("id")).toInt();
        r[QStringLiteral("name")] = m.value(QStringLiteral("name")).toString();
        r[QStringLiteral("lat")]  = m.value(QStringLiteral("lat")).toDouble();
        r[QStringLiteral("lng")]  = m.value(QStringLiteral("lng")).toDouble();
        routesArr.append(r);
    }

    QJsonArray selectedArr;
    for (const QVariant& v : std::as_const(pendingSelectedIds_))
        selectedArr.append(v.toInt());

    component_->send(QStringLiteral("setRoutes"), {
        { QStringLiteral("routes"),      QVariant(routesArr.toVariantList()) },
        { QStringLiteral("selectedIds"), QVariant(selectedArr.toVariantList()) },
    });

    pendingDirty_ = false;
}

// ── QQuickItem overrides ──────────────────────────────────────────────────────

void FlutterMapItem::geometryChange(const QRectF& newGeom, const QRectF& oldGeom)
{
    QQuickItem::geometryChange(newGeom, oldGeom);
    if (component_) {
        component_->setWidth(newGeom.width());
        component_->setHeight(newGeom.height());
    }
}

void FlutterMapItem::itemChange(ItemChange change, const ItemChangeData& value)
{
    QQuickItem::itemChange(change, value);

    if (change == ItemSceneChange && value.window) {
        if (isVisible()) ensureComponent();
    } else if (change == ItemVisibleHasChanged) {
        if (value.boolValue) ensureComponent();
        if (component_) component_->setVisible(value.boolValue);
    }
}

#endif // Q_OS_WASM
