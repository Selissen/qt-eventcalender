#ifndef SQLPLANDATABASE_H
#define SQLPLANDATABASE_H

#include <QDate>
#include <QList>
#include <QObject>
#include <QVariantList>
#include <QtQml>

#include "plan.h"

class QSqlDatabase;
class QSqlQuery;

class SqlPlanDatabase : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(PlanDatabase)
    QML_UNCREATABLE("PlanDatabase should not be created in QML")

public:
    // connectionName: unique per instance, useful for tests that need isolated databases.
    // withSampleData: seed example plans on first run; set false in tests for a clean slate.
    explicit SqlPlanDatabase(const QString &connectionName = QStringLiteral("plandb"),
                             bool withSampleData = true,
                             QObject *parent = nullptr);
    ~SqlPlanDatabase();

    QList<Plan> plansForRange(QDate start, QDate end) const;
    Plan planById(int id) const;
    Q_INVOKABLE QVariantList plansForRangeQML(QDate start, QDate end) const;

    // Called by PlanSyncManager to push server reference data into the local DB.
    // Not exposed to QML — uses INSERT OR REPLACE so existing rows are updated.
    void setUnits(const QVariantList &units);
    void setRoutes(const QVariantList &routes);

    // Called by PlanSyncManager to apply remote plan events.
    // Does NOT emit planAdded/planUpdated/planDeleted to avoid push-back to the server.
    // Emits plansChanged() so the UI refreshes.
    void applyRemotePlan(int id, const QString &name,
                         QDate startDate, int startTimeSecs,
                         QDate endDate,   int endTimeSecs,
                         int unitId, const QList<int> &routeIds);
    void applyRemoteDelete(int id);

    Q_INVOKABLE bool addPlan(const QString &name,
                             QDate startDate, int startTimeSecs,
                             QDate endDate,   int endTimeSecs,
                             int unitId, const QVariantList &routeIds);
    Q_INVOKABLE bool updatePlan(int id, const QString &name,
                                QDate startDate, int startTimeSecs,
                                QDate endDate,   int endTimeSecs,
                                int unitId, const QVariantList &routeIds);
    Q_INVOKABLE bool deletePlan(int id);

    Q_INVOKABLE QVariantList allRoutes() const;
    Q_INVOKABLE QVariantList allUnits()  const;
    Q_INVOKABLE QVariantList plannedHoursPerUnit(QDate start, QDate end) const;

    Q_PROPERTY(QVariantList unitFilter READ unitFilter WRITE setUnitFilter NOTIFY unitFilterChanged)
    QVariantList unitFilter() const;
    void setUnitFilter(const QVariantList &filter);

signals:
    void plansChanged();
    void unitFilterChanged();
    // Narrow signals emitted after the corresponding DB mutation succeeds.
    // Carry only the affected plan ID so PlanSyncManager can look up and push the change.
    void planAdded(int id);
    void planUpdated(int id);
    void planDeleted(int id);

private:
    // Returns "col IN (1,2,3)" when a unit filter is active, empty string otherwise.
    QString unitIdPredicate(const QString &column) const;

    // Inserts rows into PlanRoute for every route ID in the list.
    void insertRouteLinks(int planId, const QVariantList &routeIds, const QSqlDatabase &db);

    // Reconstructs a QDateTime from a stored date column (DATE) and a time column (INT seconds).
    static QDateTime dateTimeFromRecord(const QSqlQuery &q,
                                        const QString &dateCol,
                                        const QString &timeCol);

    void createSchema(QSqlDatabase &db);
    void seedSampleData(QSqlDatabase &db);

    QString      m_connectionName;
    QVariantList m_unitFilter;
};

#endif // SQLPLANDATABASE_H
