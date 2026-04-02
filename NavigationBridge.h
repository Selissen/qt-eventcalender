#pragma once
#ifndef Q_OS_WASM

#include <QObject>
#include <QVariantMap>

/// Mediates navigation intent between the Qt shell and the Flutter layer.
///
/// When the user triggers a screen that has been migrated to Flutter, the Qt
/// navigation code calls navigateTo() with the route path and optional params.
/// The Flutter side listens via a MethodChannel (or named-pipe IPC) and
/// activates the matching go_router route.
///
/// In Phase 0 / Phase 1 the signal is emitted but Flutter does not yet consume
/// it — wire it up when the first real screen is migrated.
class NavigationBridge : public QObject {
    Q_OBJECT
public:
    explicit NavigationBridge(QObject* parent = nullptr);

    /// Request navigation to a Flutter-owned route.
    /// @param route   go_router path, e.g. "/dashboard".
    /// @param params  Optional key/value pairs forwarded as query parameters.
    Q_INVOKABLE void navigateTo(const QString& route,
                                const QVariantMap& params = {});

signals:
    /// Emitted whenever navigateTo() is called.
    void routeRequested(const QString& route, const QVariantMap& params);
};

#endif // Q_OS_WASM
