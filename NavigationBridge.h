#pragma once
#ifndef Q_OS_WASM

#include <QObject>
#include <QVariantMap>
#include <flutter_messenger.h>

class FlutterContainer;

/// Mediates navigation between the Qt shell and the Flutter layer.
///
/// Call setFlutterContainer() once the Flutter engine is initialised and
/// embedded. After that, navigateTo() will:
///   1. Show the Flutter view (hiding the QML content behind it).
///   2. Send the route to Flutter's "navigation" BasicMessageChannel so
///      go_router can push the correct screen.
///
/// To return to Qt: call navigateToQt() (or connect a Flutter→Qt channel
/// in a later phase).
class NavigationBridge : public QObject {
    Q_OBJECT
public:
    explicit NavigationBridge(QObject* parent = nullptr);

    void setFlutterContainer(FlutterContainer* container);

    /// Navigate to a Flutter-owned go_router route, e.g. "/widget-catalog".
    Q_INVOKABLE void navigateTo(const QString& route,
                                const QVariantMap& params = {});

    /// Return to the Qt/QML view (hide Flutter).
    Q_INVOKABLE void navigateToQt();

    /// Register a callback on the "navigation/back" Flutter channel so the
    /// Flutter side can trigger a return to Qt (e.g. via a Back button).
    /// Call this once after the Flutter engine is embedded and running.
    void listenForBackNavigation(FlutterDesktopMessengerRef messenger);

signals:
    void routeRequested(const QString& route, const QVariantMap& params);
    void returnedToQt();

private:
    FlutterContainer* flutter_ = nullptr;
};

#endif // Q_OS_WASM
