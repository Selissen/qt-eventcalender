#ifndef Q_OS_WASM

#include "NavigationBridge.h"
#include "FlutterContainer.h"

#include <QDebug>

NavigationBridge::NavigationBridge(QObject* parent)
    : QObject(parent) {}

void NavigationBridge::setFlutterContainer(FlutterContainer* container)
{
    flutter_ = container;
}

void NavigationBridge::navigateTo(const QString& route,
                                  const QVariantMap& params)
{
    qDebug() << "[NavigationBridge] → Flutter route:" << route;
    emit routeRequested(route, params);

    if (!flutter_) {
        qWarning("[NavigationBridge] No FlutterContainer set — cannot navigate.");
        return;
    }

    // Send the route as a raw UTF-8 string on the "navigation" channel.
    // The Flutter side listens with BasicMessageChannel<String>(StringCodec).
    FlutterDesktopMessengerRef msg = flutter_->messenger();
    if (msg) {
        const QByteArray utf8 = route.toUtf8();
        FlutterDesktopMessengerSend(
            msg,
            "navigation",
            reinterpret_cast<const uint8_t*>(utf8.constData()),
            static_cast<size_t>(utf8.size()));
    }

    // Show Flutter on top of the QML content.
    flutter_->showEmbedded();
}

void NavigationBridge::navigateToQt()
{
    if (flutter_)
        flutter_->hideEmbedded();
    emit returnedToQt();
}

void NavigationBridge::listenForBackNavigation(FlutterDesktopMessengerRef messenger)
{
    if (!messenger) return;

    // Flutter sends an empty (or any) message on "navigation/back" to return to Qt.
    FlutterDesktopMessengerSetCallback(
        messenger,
        "navigation/back",
        [](FlutterDesktopMessengerRef m,
           const FlutterDesktopMessage* msg,
           void* user_data) {
            static_cast<NavigationBridge*>(user_data)->navigateToQt();
            // Send an empty acknowledgement so Flutter's Future completes.
            FlutterDesktopMessengerSendResponse(m, msg->response_handle, nullptr, 0);
        },
        this);
}

#endif // Q_OS_WASM
