#ifndef PLANSYNCMANAGER_H
#define PLANSYNCMANAGER_H

#include <QObject>
#include <QUrl>

class SqlPlanDatabase;

// Transport selection (compile-time):
//   EC_GRPC_ENABLED  → Qt gRPC over HTTP/2 (desktop, requires qt.qt6.addons.qtgrpc)
//   Q_OS_WASM        → QNetworkAccessManager REST/JSON (Emscripten / browser)
//   neither          → no-op (desktop without gRPC addon installed)
#if defined(EC_GRPC_ENABLED)
namespace calendar { class CalendarServiceClient; }
#elif defined(Q_OS_WASM)
class QNetworkAccessManager;
#endif

// PlanSyncManager mirrors local plan mutations to a remote backend and pulls
// reference data (units, routes) from the server on startup.
//
// It fails gracefully when the server is unreachable: a warning is logged but
// the local SqlPlanDatabase is unaffected and the app remains fully usable.
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
    void syncReferenceData();
    void pushAddedPlan(int id);
    void pushUpdatedPlan(int id);
    void pushDeletedPlan(int id);

    SqlPlanDatabase *m_db;
    QUrl             m_serverUrl;

#if defined(EC_GRPC_ENABLED)
    calendar::CalendarServiceClient *m_grpcClient = nullptr;
#elif defined(Q_OS_WASM)
    QNetworkAccessManager *m_nam = nullptr;
#endif
};

#endif // PLANSYNCMANAGER_H
