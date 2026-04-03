#include "syncbackend.h"
#include "grpcsyncbackend.h"
#include "qgrpcwebchannel.h"

#include <QGrpcChannelOptions>

// WASM factory — gRPC-Web over HTTP/1.1 via QNetworkAccessManager.
// Requires an Envoy (or compatible) proxy in front of the gRPC backend
// that translates gRPC-Web to native gRPC.
std::unique_ptr<ISyncBackend> createSyncBackend(SqlPlanDatabase *db,
                                                const QUrl &serverUrl,
                                                QObject *parent)
{
    auto channel = std::make_shared<QGrpcWebChannel>(serverUrl, QGrpcChannelOptions{});
    return std::make_unique<GrpcSyncBackend>(db, std::move(channel), parent);
}
