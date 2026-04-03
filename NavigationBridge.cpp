#ifndef Q_OS_WASM

#include "NavigationBridge.h"
#include "FlutterContainer.h"

#include <QDebug>
#include <QQuickItem>

NavigationBridge::NavigationBridge(QObject* parent)
    : QObject(parent) {}

void NavigationBridge::setFlutterContainer(FlutterContainer* container)
{
    flutter_ = container;
}

void NavigationBridge::setFlutterView(QQuickItem* view)
{
    flutterView_ = view;
}

void NavigationBridge::updateFlutterRect(int x, int y, int w, int h)
{
    if (flutter_)
        flutter_->moveToRect(x, y, w, h);
}

void NavigationBridge::setFlutterVisible(bool visible)
{
    if (!flutter_)
        return;
    if (visible)
        flutter_->showEmbedded();
    else
        flutter_->hideEmbedded();
}

// Routes handled by Flutter. Must stay in sync with the GoRoute paths
// registered in flutter/app/lib/router.dart.
static const QSet<QString> kFlutterRoutes = {
    QStringLiteral("/plans"),
    QStringLiteral("/widget-catalog"),
};

void NavigationBridge::navigateTo(const QString& route,
                                  const QVariantMap& params)
{
    qDebug() << "[NavigationBridge] → route:" << route;
    emit routeRequested(route, params);

    if (!kFlutterRoutes.contains(route)) {
        qDebug() << "[NavigationBridge] Qt-owned route, no Flutter handoff.";
        return;
    }

    // Show the FlutterView QML item; its itemChange(Visible) will call
    // setFlutterVisible(true) which forwards to flutter_->showEmbedded().
    if (flutterView_)
        flutterView_->setVisible(true);

    if (!flutter_) {
        qWarning("[NavigationBridge] No FlutterContainer set — cannot navigate.");
        return;
    }

    // Send the route as a raw UTF-8 string on the "navigation" channel.
    FlutterDesktopMessengerRef msg = flutter_->messenger();
    if (msg) {
        const QByteArray utf8 = route.toUtf8();
        FlutterDesktopMessengerSend(
            msg,
            "navigation",
            reinterpret_cast<const uint8_t*>(utf8.constData()),
            static_cast<size_t>(utf8.size()));
    }
}

void NavigationBridge::navigateToQt()
{
    if (flutterView_)
        flutterView_->setVisible(false);
    emit returnedToQt();
}

void NavigationBridge::listenForBackNavigation(FlutterDesktopMessengerRef messenger)
{
    if (!messenger) return;

    FlutterDesktopMessengerSetCallback(
        messenger,
        "navigation/back",
        [](FlutterDesktopMessengerRef m,
           const FlutterDesktopMessage* msg,
           void* user_data) {
            static_cast<NavigationBridge*>(user_data)->navigateToQt();
            FlutterDesktopMessengerSendResponse(m, msg->response_handle, nullptr, 0);
        },
        this);
}

#endif // Q_OS_WASM
