#ifndef Q_OS_WASM

#include "NavigationBridge.h"
#include <QDebug>

NavigationBridge::NavigationBridge(QObject* parent)
    : QObject(parent) {}

void NavigationBridge::navigateTo(const QString& route,
                                  const QVariantMap& params)
{
    qDebug() << "[NavigationBridge] → Flutter route:" << route << params;
    emit routeRequested(route, params);
    // TODO Phase 1: encode route + params and send via MethodChannel / named pipe
    // to the Flutter engine so go_router can push the correct screen.
}

#endif // Q_OS_WASM
