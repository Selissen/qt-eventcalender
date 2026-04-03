#pragma once
#ifndef Q_OS_WASM

#include <QObject>
#include <QVariantMap>
#include <flutter_messenger.h>

class FlutterContainer;
class QQuickItem;

/// Mediates navigation between the Qt shell and the Flutter layer.
///
/// Call setFlutterContainer() once the Flutter engine is initialised and
/// embedded, and setFlutterView() once the FlutterView QML item exists.
///
/// navigateTo() shows the FlutterView and sends the route to Flutter's
/// "navigation" BasicMessageChannel so go_router can push the correct screen.
/// navigateToQt() hides the FlutterView and returns focus to QML.
class NavigationBridge : public QObject {
    Q_OBJECT
public:
    explicit NavigationBridge(QObject* parent = nullptr);

    void setFlutterContainer(FlutterContainer* container);

    /// Called by FlutterView when its bridge property is set.
    void setFlutterView(QQuickItem* view);

    /// Called by FlutterView's geometryChange() to reposition the HWND.
    Q_INVOKABLE void updateFlutterRect(int x, int y, int w, int h);

    /// Called by FlutterView's itemChange(Visible) to show/hide the HWND.
    Q_INVOKABLE void setFlutterVisible(bool visible);

    /// Navigate to a Flutter-owned go_router route, e.g. "/plans".
    Q_INVOKABLE void navigateTo(const QString& route,
                                const QVariantMap& params = {});

    /// Return to the Qt/QML view (hide Flutter).
    Q_INVOKABLE void navigateToQt();

    /// Register a callback on the "navigation/back" Flutter channel so the
    /// Flutter side can trigger a return to Qt (e.g. via a Back button).
    void listenForBackNavigation(FlutterDesktopMessengerRef messenger);

signals:
    void routeRequested(const QString& route, const QVariantMap& params);
    void returnedToQt();

private:
    FlutterContainer* flutter_     = nullptr;
    QQuickItem*       flutterView_ = nullptr;
};

#endif // Q_OS_WASM
