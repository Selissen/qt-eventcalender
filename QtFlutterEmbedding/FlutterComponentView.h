#pragma once
#ifndef Q_OS_WASM

#include <QQuickItem>
#include <QTimer>
#include <QVariantMap>
#include <windows.h>
#include <flutter_windows.h>

class ComponentBridge;

/// Generic QQuickItem that embeds any Flutter component inside the QML tree.
///
/// Set `entrypoint` to the @pragma('vm:entry-point') Dart function in main.dart,
/// and `channel` to the agreed BasicMessageChannel name.  The item manages its
/// own engine lifecycle, HWND embedding, and message bridge.
///
/// QML usage:
///   FlutterComponentView {
///       entrypoint:   "mapComponentMain"
///       channel:      "com.eventcalendar/map"
///       artifactsDir: "/path/to/flutter/build"  // optional; defaults to exe dir
///       visible:      sidebar.isEditing
///       Layout.fillWidth: true; Layout.fillHeight: true
///
///       onReadyChanged: if (ready) send("init", {key: value})
///       onMessageReceived: (method, args) => handleMessage(method, args)
///   }
///
/// Adding a new component:
///   1. Write a @pragma('vm:entry-point') void myMain() in flutter/app/lib/main.dart
///   2. Place FlutterComponentView { entrypoint:"myMain"; channel:"com.eventcalendar/my" }
///      anywhere in QML — no C++ changes required.
class FlutterComponentView : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QString entrypoint   READ entrypoint   WRITE setEntrypoint   NOTIFY entrypointChanged)
    Q_PROPERTY(QString channel      READ channel      WRITE setChannel      NOTIFY channelChanged)
    Q_PROPERTY(QString artifactsDir READ artifactsDir WRITE setArtifactsDir NOTIFY artifactsDirChanged)
    Q_PROPERTY(bool    ready        READ ready                               NOTIFY readyChanged)
    QML_ELEMENT
public:
    explicit FlutterComponentView(QQuickItem* parent = nullptr);
    ~FlutterComponentView() override;

    QString entrypoint()   const { return entrypoint_; }
    QString channel()      const { return channel_; }
    /// Per-component artifacts directory override.
    /// Empty (default) means use ComponentEngineFactory::artifactsDir().
    QString artifactsDir() const { return artifactsDir_; }
    bool    ready()        const { return dartReady_; }

    void setEntrypoint(const QString& v);
    void setChannel(const QString& v);
    void setArtifactsDir(const QString& v);

    /// Send a JSON message to the Flutter component.
    /// Can be called before the engine is ready — messages are queued and
    /// flushed in order once Flutter signals "ready".
    Q_INVOKABLE void send(const QString& method, const QVariantMap& args = {});

signals:
    void entrypointChanged();
    void channelChanged();
    void artifactsDirChanged();
    /// Emitted once after Flutter's first frame registers its message handler.
    void readyChanged();
    /// Emitted for every message the Flutter component sends back.
    void messageReceived(const QString& method, const QVariantMap& args);

protected:
    void geometryChange(const QRectF& newGeom, const QRectF& oldGeom) override;
    void itemChange(ItemChange change, const ItemChangeData& value) override;

private:
    void ensureEngine();
    void syncRect();
    void syncVisibility(bool visible);
    void flushPending();

    QString entrypoint_;
    QString channel_;
    QString artifactsDir_;

    FlutterDesktopViewControllerRef controller_ = nullptr;
    ComponentBridge*                bridge_     = nullptr;
    QTimer*                         loopTimer_  = nullptr;

    bool dartReady_ = false;

    struct Msg { QString method; QVariantMap args; };
    QVector<Msg> pending_;
};

#endif // Q_OS_WASM
