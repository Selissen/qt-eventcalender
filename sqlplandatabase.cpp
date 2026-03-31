#include "sqlplandatabase.h"

#include <QDebug>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariantMap>

#ifdef Q_OS_WASM
#  include <QDir>
#  include <QFile>
#  include <QStandardPaths>
#endif

// ── Construction / destruction ───────────────────────────────────────────────

SqlPlanDatabase::SqlPlanDatabase(const QString &connectionName,
                                 bool withSampleData,
                                 QObject *parent)
    : QObject(parent)
    , m_connectionName(connectionName)
{
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", m_connectionName);

#ifdef Q_OS_WASM
    // On WebAssembly, Qt mounts the AppDataLocation path to IndexedDB (IDBFS),
    // giving us persistent storage that survives page reloads.
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    const QString dbPath = dataDir + "/plans.db";
    const bool isNewDb = !QFile::exists(dbPath);
    db.setDatabaseName(dbPath);
#else
    // Desktop: in-memory database; fast and isolated per run.
    db.setDatabaseName(":memory:");
    constexpr bool isNewDb = true;
#endif

    if (!db.open()) {
        qFatal("Cannot open plan database: %s", qPrintable(db.lastError().text()));
        return;
    }
    createSchema(db);
    if (isNewDb && withSampleData)
        seedSampleData(db);
}

SqlPlanDatabase::~SqlPlanDatabase()
{
    QSqlDatabase::removeDatabase(m_connectionName);
}

// ── Unit filter ──────────────────────────────────────────────────────────────

QVariantList SqlPlanDatabase::unitFilter() const { return m_unitFilter; }

void SqlPlanDatabase::setUnitFilter(const QVariantList &filter)
{
    m_unitFilter = filter;
    emit unitFilterChanged();
    emit plansChanged();
}

// ── Private helpers ──────────────────────────────────────────────────────────

QString SqlPlanDatabase::unitIdPredicate(const QString &column) const
{
    if (m_unitFilter.isEmpty())
        return {};
    QStringList ids;
    ids.reserve(m_unitFilter.size());
    for (const QVariant &v : m_unitFilter)
        ids << QString::number(v.toInt());
    return column + " IN (" + ids.join(QLatin1Char(',')) + ")";
}

void SqlPlanDatabase::insertRouteLinks(int planId,
                                       const QVariantList &routeIds,
                                       const QSqlDatabase &db)
{
    for (const QVariant &rv : routeIds) {
        QSqlQuery rq(db);
        rq.prepare("INSERT INTO PlanRoute (plan_id, route_id) VALUES (:planId, :routeId)");
        rq.bindValue(":planId",  planId);
        rq.bindValue(":routeId", rv.toInt());
        if (!rq.exec())
            qWarning() << "insertRouteLinks failed:" << rq.lastError();
    }
}

QDateTime SqlPlanDatabase::dateTimeFromRecord(const QSqlQuery &q,
                                               const QString &dateCol,
                                               const QString &timeCol)
{
    QDateTime dt;
    dt.setDate(q.value(dateCol).toDate());
    dt.setTime(QTime(0, 0).addSecs(q.value(timeCol).toInt()));
    return dt;
}

// ── Public queries ───────────────────────────────────────────────────────────

QList<Plan> SqlPlanDatabase::plansForRange(QDate start, QDate end) const
{
    auto db = QSqlDatabase::database(m_connectionName);

    // Overlap: a plan overlaps [start, end] when plan.start <= end AND plan.end >= start.
    QString sql =
        "SELECT p.id, p.name, p.startDate, p.startTime, p.endDate, p.endTime, "
        "       p.unit_id, u.name AS unitName "
        "FROM Plan p JOIN Unit u ON p.unit_id = u.id "
        "WHERE p.startDate <= :rangeEnd AND p.endDate >= :rangeStart";

    const QString pred = unitIdPredicate("p.unit_id");
    if (!pred.isEmpty())
        sql += " AND " + pred;

    sql += " ORDER BY p.startDate, p.startTime";

    QSqlQuery query(db);
    query.prepare(sql);
    query.bindValue(":rangeStart", start.toString("yyyy-MM-dd"));
    query.bindValue(":rangeEnd",   end.toString("yyyy-MM-dd"));

    if (!query.exec()) {
        qWarning() << "plansForRange failed:" << query.lastError();
        return {};
    }

    QList<Plan> plans;
    while (query.next()) {
        Plan plan;
        plan.id        = query.value("id").toInt();
        plan.name      = query.value("name").toString();
        plan.unitId    = query.value("unit_id").toInt();
        plan.unitName  = query.value("unitName").toString();
        plan.startDate = dateTimeFromRecord(query, "startDate", "startTime");
        plan.endDate   = dateTimeFromRecord(query, "endDate",   "endTime");

        QSqlQuery routeQ(db);
        routeQ.prepare("SELECT route_id FROM PlanRoute WHERE plan_id = :id");
        routeQ.bindValue(":id", plan.id);
        if (routeQ.exec()) {
            while (routeQ.next())
                plan.routeIds.append(routeQ.value(0).toInt());
        }
        plans.append(plan);
    }
    return plans;
}

QVariantList SqlPlanDatabase::plansForRangeQML(QDate start, QDate end) const
{
    QVariantList result;
    const QList<Plan> plans = plansForRange(start, end);
    result.reserve(plans.size());
    for (const Plan &p : plans) {
        QVariantMap m;
        m[QStringLiteral("planId")]    = p.id;
        m[QStringLiteral("name")]      = p.name;
        m[QStringLiteral("startDate")] = p.startDate;
        m[QStringLiteral("endDate")]   = p.endDate;
        m[QStringLiteral("unitId")]    = p.unitId;
        m[QStringLiteral("unitName")]  = p.unitName;
        QVariantList rids;
        rids.reserve(p.routeIds.size());
        for (int id : p.routeIds) rids << id;
        m[QStringLiteral("routeIds")] = rids;
        result << m;
    }
    return result;
}

bool SqlPlanDatabase::addPlan(const QString &name,
                               QDate startDate, int startTimeSecs,
                               QDate endDate,   int endTimeSecs,
                               int unitId, const QVariantList &routeIds)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO Plan (name, startDate, startTime, endDate, endTime, unit_id) "
        "VALUES (:name, :startDate, :startTime, :endDate, :endTime, :unitId)"
    );
    query.bindValue(":name",      name);
    query.bindValue(":startDate", startDate.toString("yyyy-MM-dd"));
    query.bindValue(":startTime", startTimeSecs);
    query.bindValue(":endDate",   endDate.toString("yyyy-MM-dd"));
    query.bindValue(":endTime",   endTimeSecs);
    query.bindValue(":unitId",    unitId);
    if (!query.exec()) {
        qWarning() << "addPlan failed:" << query.lastError();
        return false;
    }
    insertRouteLinks(query.lastInsertId().toInt(), routeIds, db);
    emit plansChanged();
    return true;
}

bool SqlPlanDatabase::updatePlan(int id, const QString &name,
                                  QDate startDate, int startTimeSecs,
                                  QDate endDate,   int endTimeSecs,
                                  int unitId, const QVariantList &routeIds)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(
        "UPDATE Plan SET name=:name, startDate=:startDate, startTime=:startTime, "
        "endDate=:endDate, endTime=:endTime, unit_id=:unitId WHERE id=:id"
    );
    query.bindValue(":name",      name);
    query.bindValue(":startDate", startDate.toString("yyyy-MM-dd"));
    query.bindValue(":startTime", startTimeSecs);
    query.bindValue(":endDate",   endDate.toString("yyyy-MM-dd"));
    query.bindValue(":endTime",   endTimeSecs);
    query.bindValue(":unitId",    unitId);
    query.bindValue(":id",        id);
    if (!query.exec()) {
        qWarning() << "updatePlan failed:" << query.lastError();
        return false;
    }

    QSqlQuery delQ(db);
    delQ.prepare("DELETE FROM PlanRoute WHERE plan_id = :id");
    delQ.bindValue(":id", id);
    delQ.exec();

    insertRouteLinks(id, routeIds, db);
    emit plansChanged();
    return true;
}

bool SqlPlanDatabase::deletePlan(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);

    QSqlQuery delRoutes(db);
    delRoutes.prepare("DELETE FROM PlanRoute WHERE plan_id = :id");
    delRoutes.bindValue(":id", id);
    delRoutes.exec();

    QSqlQuery query(db);
    query.prepare("DELETE FROM Plan WHERE id = :id");
    query.bindValue(":id", id);
    if (!query.exec()) {
        qWarning() << "deletePlan failed:" << query.lastError();
        return false;
    }
    emit plansChanged();
    return true;
}

QVariantList SqlPlanDatabase::allRoutes() const
{
    QSqlQuery query(QSqlDatabase::database(m_connectionName));
    query.exec("SELECT id, name FROM Route ORDER BY id");
    QVariantList result;
    while (query.next()) {
        QVariantMap m;
        m[QStringLiteral("id")]   = query.value("id");
        m[QStringLiteral("name")] = query.value("name");
        result.append(m);
    }
    return result;
}

QVariantList SqlPlanDatabase::allUnits() const
{
    QSqlQuery query(QSqlDatabase::database(m_connectionName));
    query.exec("SELECT id, name FROM Unit ORDER BY id");
    QVariantList result;
    while (query.next()) {
        QVariantMap m;
        m[QStringLiteral("id")]   = query.value("id");
        m[QStringLiteral("name")] = query.value("name");
        result.append(m);
    }
    return result;
}

QVariantList SqlPlanDatabase::plannedHoursPerUnit(QDate start, QDate end) const
{
    auto db = QSqlDatabase::database(m_connectionName);

    // LEFT JOIN ensures every unit (subject to the filter) always gets a row,
    // even when it has no plans in the requested range.
    QString sql =
        "SELECT u.id AS unitId, u.name AS unitName, "
        "       COALESCE(SUM("
        "           (julianday(p.endDate) - julianday(p.startDate)) * 86400.0"
        "           + p.endTime - p.startTime"
        "       ), 0.0) AS totalSecs "
        "FROM Unit u "
        "LEFT JOIN Plan p ON p.unit_id = u.id "
        "    AND p.startDate <= :rangeEnd AND p.endDate >= :rangeStart ";

    const QString pred = unitIdPredicate("u.id");
    if (!pred.isEmpty())
        sql += "WHERE " + pred + " ";

    sql += "GROUP BY u.id, u.name ORDER BY u.id";

    QSqlQuery query(db);
    query.prepare(sql);
    query.bindValue(":rangeStart", start.toString("yyyy-MM-dd"));
    query.bindValue(":rangeEnd",   end.toString("yyyy-MM-dd"));

    if (!query.exec()) {
        qWarning() << "plannedHoursPerUnit failed:" << query.lastError();
        return {};
    }

    QVariantList result;
    while (query.next()) {
        QVariantMap m;
        m[QStringLiteral("unitId")]   = query.value("unitId");
        m[QStringLiteral("unitName")] = query.value("unitName");
        m[QStringLiteral("hours")]    = query.value("totalSecs").toDouble() / 3600.0;
        result.append(m);
    }
    return result;
}

// ── Schema & seed data ───────────────────────────────────────────────────────

void SqlPlanDatabase::createSchema(QSqlDatabase &db)
{
    // IF NOT EXISTS / INSERT OR IGNORE make this safe to call against a
    // persisted WASM database that already has schema and reference data.
    QSqlQuery q(db);
    q.exec("CREATE TABLE IF NOT EXISTS Unit ("
           "  id   INTEGER PRIMARY KEY,"
           "  name TEXT NOT NULL"
           ")");
    q.exec("INSERT OR IGNORE INTO Unit (id, name) VALUES (1, 'Unit 1')");
    q.exec("INSERT OR IGNORE INTO Unit (id, name) VALUES (2, 'Unit 2')");
    q.exec("INSERT OR IGNORE INTO Unit (id, name) VALUES (3, 'Unit 3')");

    q.exec("CREATE TABLE IF NOT EXISTS Route ("
           "  id   INTEGER PRIMARY KEY,"
           "  name TEXT NOT NULL"
           ")");
    q.exec("INSERT OR IGNORE INTO Route (id, name) VALUES (1, 'Route A')");
    q.exec("INSERT OR IGNORE INTO Route (id, name) VALUES (2, 'Route B')");
    q.exec("INSERT OR IGNORE INTO Route (id, name) VALUES (3, 'Route C')");
    q.exec("INSERT OR IGNORE INTO Route (id, name) VALUES (4, 'Route D')");

    q.exec("CREATE TABLE IF NOT EXISTS Plan ("
           "  id        INTEGER PRIMARY KEY AUTOINCREMENT,"
           "  name      TEXT,"
           "  startDate DATE,"
           "  startTime INT,"
           "  endDate   DATE,"
           "  endTime   INT,"
           "  unit_id   INTEGER NOT NULL,"
           "  FOREIGN KEY(unit_id) REFERENCES Unit(id)"
           ")");

    q.exec("CREATE TABLE IF NOT EXISTS PlanRoute ("
           "  plan_id  INTEGER NOT NULL,"
           "  route_id INTEGER NOT NULL,"
           "  PRIMARY KEY(plan_id, route_id),"
           "  FOREIGN KEY(plan_id)  REFERENCES Plan(id),"
           "  FOREIGN KEY(route_id) REFERENCES Route(id)"
           ")");
}

void SqlPlanDatabase::seedSampleData(QSqlDatabase &db)
{
    const QString y = QDate::currentDate().toString("yyyy");
    const QString m = QDate::currentDate().toString("MM");

    QSqlQuery q(db);
    // plan 1 — day 1, Unit 1, 08:00–09:00
    q.exec(QString::fromLatin1("INSERT INTO Plan (name, startDate, startTime, endDate, endTime, unit_id) "
           "VALUES ('Site Inspection', '%1-%2-01', 28800, '%1-%2-01', 32400, 1)").arg(y, m));
    // plan 2 — day 1, Unit 2, 20:00–21:00
    q.exec(QString::fromLatin1("INSERT INTO Plan (name, startDate, startTime, endDate, endTime, unit_id) "
           "VALUES ('Evening Patrol', '%1-%2-01', 72000, '%1-%2-01', 75600, 2)").arg(y, m));
    // plan 3 — day 5, Unit 1, 09:00–11:00
    q.exec(QString::fromLatin1("INSERT INTO Plan (name, startDate, startTime, endDate, endTime, unit_id) "
           "VALUES ('Morning Route', '%1-%2-05', 32400, '%1-%2-05', 39600, 1)").arg(y, m));
    // plan 4 — day 5, Unit 2, 12:00–16:00
    q.exec(QString::fromLatin1("INSERT INTO Plan (name, startDate, startTime, endDate, endTime, unit_id) "
           "VALUES ('Afternoon Route', '%1-%2-05', 43200, '%1-%2-05', 57600, 2)").arg(y, m));
    // plan 5 — day 15, Unit 3, 10:00–12:00
    q.exec(QString::fromLatin1("INSERT INTO Plan (name, startDate, startTime, endDate, endTime, unit_id) "
           "VALUES ('Area Survey', '%1-%2-15', 36000, '%1-%2-15', 43200, 3)").arg(y, m));
    // plan 6 — day 20–22, Unit 1, 07:00–18:00
    q.exec(QString::fromLatin1("INSERT INTO Plan (name, startDate, startTime, endDate, endTime, unit_id) "
           "VALUES ('Multi-day Exercise', '%1-%2-20', 25200, '%1-%2-22', 64800, 1)").arg(y, m));

    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (1, 1)");  // Site Inspection → A
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (2, 4)");  // Evening Patrol  → D
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (3, 1)");  // Morning Route   → A
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (3, 2)");  // Morning Route   → B
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (4, 3)");  // Afternoon Route → C
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (5, 2)");  // Area Survey     → B
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (5, 3)");  // Area Survey     → C
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (6, 1)");  // Multi-day       → A
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (6, 2)");  // Multi-day       → B
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (6, 3)");  // Multi-day       → C
    q.exec("INSERT INTO PlanRoute (plan_id, route_id) VALUES (6, 4)");  // Multi-day       → D
}
