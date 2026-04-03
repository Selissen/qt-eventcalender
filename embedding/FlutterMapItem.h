#pragma once
#ifndef Q_OS_WASM

#include <QQuickItem>
#include <QTimer>
#include <QVariantList>
#include <windows.h>
#include <flutter_windows.h>

class ComponentBridge;

/// A self-contained QQuickItem that embeds the Flutter map component.
///
/// Place this in QML with normal anchors/layouts; it manages its own
/// Flutter engine, HWND embedding, and ComponentBridge lifecycle.
///
/// Usage in QML:
///   FlutterMapItem {
///       visible: sidebar.isEditing
///       Layout.fillWidth: true
///       Layout.fillHeight: true
///   }
///
/// To push route data from QML:
///   mapItem.updateRoutes(allRoutesArray, selectedIdsArray)
///
/// allRoutesArray: list of {id, name, lat, lng}
/// selectedIdsArray: list of route IDs currently checked
class FlutterMapItem : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
public:
    explicit FlutterMapItem(QQuickItem* parent = nullptr);
    ~FlutterMapItem() override;

    /// Push all routes and the currently selected subset to the Flutter map.
    /// allRoutes: QVariantList of QVariantMap with keys {id, name, lat, lng}
    /// selectedIds: QVariantList of int
    Q_INVOKABLE void updateRoutes(const QVariantList& allRoutes,
                                  const QVariantList& selectedIds);

signals:
    /// Emitted when the user taps a route marker on the Flutter map.
    /// Connect this in QML to toggle the matching checkbox in EventSidebar.
    void routeToggled(int routeId);

protected:
    void geometryChange(const QRectF& newGeom, const QRectF& oldGeom) override;
    void itemChange(ItemChange change, const ItemChangeData& value) override;

private:
    void ensureEngine();
    void syncRect();
    void syncVisibility(bool visible);
    void flushPendingRoutes();

    FlutterDesktopViewControllerRef controller_ = nullptr;
    ComponentBridge*                bridge_     = nullptr;
    QTimer*                         loopTimer_  = nullptr;

    // Routes are held until Flutter sends the "ready" ping, guaranteeing the
    // Dart message handler is registered before we push data.
    bool         dartReady_         = false;
    bool         pendingDirty_      = false;
    QVariantList pendingAllRoutes_;
    QVariantList pendingSelectedIds_;
};

#endif // Q_OS_WASM
