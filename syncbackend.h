#ifndef SYNCBACKEND_H
#define SYNCBACKEND_H

#include <QObject>
#include <QUrl>
#include <memory>

class SqlPlanDatabase;

// Abstract sync transport. Concrete subclasses implement gRPC/HTTP-2 (desktop),
// gRPC-Web (WASM), or no-op (when gRPC addon is not installed).
//
// createSyncBackend() is defined in exactly one of the backend/factory .cpp
// files, selected at compile time by CMakeLists.txt.
class ISyncBackend : public QObject
{
    Q_OBJECT
public:
    explicit ISyncBackend(SqlPlanDatabase *db, QObject *parent = nullptr)
        : QObject(parent), m_db(db) {}

    ~ISyncBackend() override = default;

    // Pull reference data (units, routes) from the server on startup.
    virtual void syncReferenceData() = 0;

    // Open a server-streaming subscription for live plan updates.
    // Default is a no-op; only gRPC backends override this.
    virtual void startSubscription() {}

public slots:
    virtual void pushAddedPlan(int id)   = 0;
    virtual void pushUpdatedPlan(int id) = 0;
    virtual void pushDeletedPlan(int id) = 0;

protected:
    SqlPlanDatabase *m_db;
};

std::unique_ptr<ISyncBackend> createSyncBackend(SqlPlanDatabase *db,
                                                const QUrl &serverUrl,
                                                QObject *parent = nullptr);

#endif // SYNCBACKEND_H
