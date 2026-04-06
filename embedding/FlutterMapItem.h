#pragma once
#ifndef Q_OS_WASM

#include <QQuickItem>
#include <QVariantList>

class FlutterComponentView;

/// A self-contained QQuickItem that embeds the Flutter map component.
///
/// Wraps FlutterComponentView with the map-specific entry point, channel, and
/// a typed domain API (updateRoutes / routeToggled) so callers never deal with
/// raw JSON or channel strings.
///
/// QML usage:
///   FlutterMapItem {
///       instanceId: "planning"       // optional; omit for single-instance use
///       visible:    sidebar.isEditing
///       Layout.fillWidth:  true
///       Layout.fillHeight: true
///       onRouteToggled: (id) => sidebar.toggleRoute(id)
///       onEngineError:  (msg) => console.warn("map error:", msg)
///   }
///
/// Push route data from QML or C++:
///   mapItem.updateRoutes(allRoutesArray, selectedIdsArray)
///
/// allRoutesArray:  list of { id, name, lat, lng }
/// selectedIdsArray: list of int route IDs currently selected
class FlutterMapItem : public QQuickItem {
    Q_OBJECT
    /// Unique identifier for this map instance.
    /// When non-empty the actual bridge channel becomes
    /// "com.eventcalendar/map/<instanceId>", matching what the C++ factory
    /// and the Dart entry point both derive from the same value.
    /// Leave empty (default) for single-instance use.
    Q_PROPERTY(QString instanceId READ instanceId WRITE setInstanceId
                                  NOTIFY instanceIdChanged)
    QML_ELEMENT
public:
    explicit FlutterMapItem(QQuickItem* parent = nullptr);

    QString instanceId() const { return instanceId_; }
    void setInstanceId(const QString& v);

    /// Push all routes and the currently selected subset to the Flutter map.
    /// Buffered until Flutter sends the "ready" ping; safe to call at any time.
    Q_INVOKABLE void updateRoutes(const QVariantList& allRoutes,
                                  const QVariantList& selectedIds);

signals:
    void instanceIdChanged();
    /// Emitted when the user taps a route marker on the Flutter map.
    void routeToggled(int routeId);
    /// Emitted when the Flutter map engine fails to start.
    void engineError(const QString& reason);

protected:
    void geometryChange(const QRectF& newGeom, const QRectF& oldGeom) override;
    void itemChange(ItemChange change, const ItemChangeData& value) override;

private:
    void ensureComponent();
    void flushPendingRoutes();

    QString              instanceId_;
    FlutterComponentView* component_  = nullptr;

    // Routes buffered until FlutterComponentView signals ready.
    bool         pendingDirty_      = false;
    QVariantList pendingAllRoutes_;
    QVariantList pendingSelectedIds_;
};

#endif // Q_OS_WASM
