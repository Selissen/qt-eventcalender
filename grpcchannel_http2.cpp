#include "syncbackend.h"
#include "grpcsyncbackend.h"

#include <QGrpcHttp2Channel>
#include <QGrpcChannelOptions>

// Desktop factory — native gRPC over HTTP/2.
std::unique_ptr<ISyncBackend> createSyncBackend(SqlPlanDatabase *db,
                                                const QUrl &serverUrl,
                                                QObject *parent)
{
    auto channel = std::make_shared<QGrpcHttp2Channel>(serverUrl, QGrpcChannelOptions{});
    return std::make_unique<GrpcSyncBackend>(db, std::move(channel), parent);
}
