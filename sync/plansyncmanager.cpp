#include "plansyncmanager.h"
#include "syncbackend.h"
#include "sqlplandatabase.h"

PlanSyncManager::PlanSyncManager(SqlPlanDatabase *db, const QUrl &serverUrl, QObject *parent)
    : QObject(parent)
    , m_db(db)
    , m_backend(createSyncBackend(db, serverUrl))
{}

PlanSyncManager::~PlanSyncManager() = default;

void PlanSyncManager::start()
{
    connect(m_db, &SqlPlanDatabase::planAdded,   m_backend.get(), &ISyncBackend::pushAddedPlan);
    connect(m_db, &SqlPlanDatabase::planUpdated, m_backend.get(), &ISyncBackend::pushUpdatedPlan);
    connect(m_db, &SqlPlanDatabase::planDeleted, m_backend.get(), &ISyncBackend::pushDeletedPlan);

    m_backend->syncReferenceData();
    m_backend->startSubscription();
}
