#include "noopsyncbackend.h"
#include <QDebug>

NoopSyncBackend::NoopSyncBackend(SqlPlanDatabase *db, const QUrl &serverUrl, QObject *parent)
    : ISyncBackend(db, parent)
{
    qDebug() << "[PlanSyncManager] No transport available — sync disabled."
             << "Server URL was:" << serverUrl.toString()
             << "— Install protoc and qt.qt6.addons.qtgrpc to enable gRPC.";
}

std::unique_ptr<ISyncBackend> createSyncBackend(SqlPlanDatabase *db,
                                                const QUrl &serverUrl,
                                                QObject *parent)
{
    return std::make_unique<NoopSyncBackend>(db, serverUrl, parent);
}
