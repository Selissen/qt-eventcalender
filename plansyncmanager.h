#ifndef PLANSYNCMANAGER_H
#define PLANSYNCMANAGER_H

#include <QObject>
#include <QUrl>
#include <memory>

class SqlPlanDatabase;
class ISyncBackend;

// PlanSyncManager mirrors local plan mutations to a remote backend and pulls
// reference data (units, routes) from the server on startup.
//
// Transport is selected at compile time by CMakeLists.txt:
//   Qt6Grpc + desktop  → GrpcSyncBackend + QGrpcHttp2Channel  (native gRPC)
//   Qt6Grpc + WASM     → GrpcSyncBackend + QGrpcWebChannel    (gRPC-Web via Envoy)
//   Qt6Grpc not found  → NoopSyncBackend                      (graceful no-op)
//
// The app remains fully usable when the server is unreachable — failures are
// logged as warnings but the local SqlPlanDatabase is never affected.
class PlanSyncManager : public QObject
{
    Q_OBJECT
public:
    explicit PlanSyncManager(SqlPlanDatabase *db, const QUrl &serverUrl,
                             QObject *parent = nullptr);
    ~PlanSyncManager() override;

    // Connect to SqlPlanDatabase signals and trigger the initial reference-data pull.
    void start();

private:
    SqlPlanDatabase              *m_db;
    std::unique_ptr<ISyncBackend> m_backend;
};

#endif // PLANSYNCMANAGER_H
