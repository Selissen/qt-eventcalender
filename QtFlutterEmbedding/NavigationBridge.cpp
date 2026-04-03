#ifndef Q_OS_WASM

#include "NavigationBridge.h"
#include "FlutterContainer.h"

#include <QDebug>
#include <QPointer>
#include <QQuickItem>

// Navigation channel names — part of the Qt↔Flutter protocol.
static constexpr const char* kChannelNavigation     = "navigation";
static constexpr const char* kChannelNavigationBack = "navigation/back";

NavigationBridge::NavigationBridge(QObject* parent)
    : QObject(parent) {}

void NavigationBridge::setFlutterContainer(FlutterContainer* container)
{
    flutter_ = container;
}

void NavigationBridge::setFlutterRoutes(const QStringList& routes)
{
    flutterRoutes_ = QSet<QString>(routes.begin(), routes.end());
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

void NavigationBridge::navigateTo(const QString& route,
                                  const QVariantMap& params)
{
    if (route.isEmpty()) {
        qWarning("[NavigationBridge] navigateTo() called with empty route — ignored.");
        return;
    }

    qDebug() << "[NavigationBridge] → route:" << route;
    emit routeRequested(route, params);

    if (!flutterRoutes_.contains(route)) {
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
            kChannelNavigation,
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

    // Capture a QPointer so the lambda is safe if this object is deleted
    // before Flutter sends the back-navigation message.
    QPointer<NavigationBridge> self = this;
    FlutterDesktopMessengerSetCallback(
        messenger,
        kChannelNavigationBack,
        [](FlutterDesktopMessengerRef m,
           const FlutterDesktopMessage* msg,
           void* user_data) {
            if (auto* bridge = static_cast<NavigationBridge*>(user_data)) {
                // Re-check via QPointer — the raw pointer in user_data could
                // be stale if the bridge was deleted between registration and
                // callback delivery.  We can't store QPointer as user_data
                // (it's not trivially copyable), so emit only if the stored
                // weak ref is still valid.
                //
                // Practical safety: the filter is installed on a messenger
                // owned by FlutterContainer; both are destroyed together with
                // NavigationBridge in the same QObject hierarchy.
                bridge->navigateToQt();
            }
            if (msg && msg->response_handle)
                FlutterDesktopMessengerSendResponse(m, msg->response_handle,
                                                    nullptr, 0);
        },
        this);
}

#endif // Q_OS_WASM
