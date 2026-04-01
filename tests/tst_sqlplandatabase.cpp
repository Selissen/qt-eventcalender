// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QtTest>
#include "sqlplandatabase.h"

// All tests use a private in-memory database ("test_plandb") with no sample
// data so each test controls its own fixtures.

class TestSqlPlanDatabase : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();

    // allUnits / allRoutes
    void allUnits_returnsThreeUnits();
    void allRoutes_returnsFourRoutes();

    // addPlan + plansForRange
    void addPlan_planIsRetrievable();
    void addPlan_withRoutes_routesAreStored();
    void addPlan_emitsPlansChanged();

    // plansForRange — overlap semantics
    void plansForRange_planOnExactDay();
    void plansForRange_planOutsideRange_notReturned();
    void plansForRange_multiDayPlan_appearsOnAllOverlappingDays();
    void plansForRange_unitFilter_restrictsResults();

    // updatePlan
    void updatePlan_updatesFieldsAndRoutes();

    // deletePlan
    void deletePlan_removesFromDatabase();
    void deletePlan_cascadesRouteDeletion();

    // plannedHoursPerUnit
    void plannedHoursPerUnit_correctHoursForSinglePlan();
    void plannedHoursPerUnit_multiDayPlan_correctTotalHours();
    void plannedHoursPerUnit_allUnitsAppearsEvenWithZeroHours();
    void plannedHoursPerUnit_unitFilter_restrictsUnits();

    // unitFilter property
    void unitFilter_setFilter_emitsSignals();
    void unitFilter_clearFilter_showsAllPlans();

    // planById
    void planById_existingPlan_returnsCorrectData();
    void planById_missingPlan_returnsInvalidPlan();

    // plansForRangeQML — shape of returned QVariantMap
    void plansForRangeQML_shape();

    // setUnits / setRoutes
    void setUnits_replacesExistingUnit();
    void setRoutes_replacesExistingRoute();

    // applyRemotePlan / applyRemoteDelete
    void applyRemotePlan_insertsNewPlan();
    void applyRemotePlan_updatesExistingPlan();
    void applyRemotePlan_doesNotEmitPlanAdded();
    void applyRemoteDelete_removesPlan();
    void applyRemoteDelete_doesNotEmitPlanDeleted();

private:
    SqlPlanDatabase *m_db = nullptr;

    // Fixed dates that never depend on the current system date.
    static constexpr int kYear  = 2026;
    static constexpr int kMonth = 6;

    QDate date(int day) const { return {kYear, kMonth, day}; }

    // Convenience: add a plan and return the first plan in the result
    // (assumes the caller added exactly one plan for the given day).
    Plan firstPlanOnDay(int day)
    {
        auto plans = m_db->plansForRange(date(day), date(day));
        return plans.isEmpty() ? Plan{} : plans.first();
    }
};

// ── Fixture ───────────────────────────────────────────────────────────────────

void TestSqlPlanDatabase::init()
{
    m_db = new SqlPlanDatabase("test_plandb", /*withSampleData=*/false, this);
}

void TestSqlPlanDatabase::cleanup()
{
    delete m_db;
    m_db = nullptr;
}

// ── allUnits / allRoutes ──────────────────────────────────────────────────────

void TestSqlPlanDatabase::allUnits_returnsThreeUnits()
{
    const QVariantList units = m_db->allUnits();
    QCOMPARE(units.size(), 3);
    QCOMPARE(units[0].toMap()["name"].toString(), QStringLiteral("Unit 1"));
    QCOMPARE(units[1].toMap()["name"].toString(), QStringLiteral("Unit 2"));
    QCOMPARE(units[2].toMap()["name"].toString(), QStringLiteral("Unit 3"));
    QCOMPARE(units[0].toMap()["id"].toInt(), 1);
}

void TestSqlPlanDatabase::allRoutes_returnsFourRoutes()
{
    const QVariantList routes = m_db->allRoutes();
    QCOMPARE(routes.size(), 4);
    QCOMPARE(routes[0].toMap()["name"].toString(), QStringLiteral("Route A"));
    QCOMPARE(routes[3].toMap()["name"].toString(), QStringLiteral("Route D"));
}

// ── addPlan + plansForRange ───────────────────────────────────────────────────

void TestSqlPlanDatabase::addPlan_planIsRetrievable()
{
    m_db->addPlan("Test Plan", date(10), 3600, date(10), 7200, 1, {});

    const Plan p = firstPlanOnDay(10);
    QCOMPARE(p.name,     QStringLiteral("Test Plan"));
    QCOMPARE(p.unitId,   1);
    QCOMPARE(p.unitName, QStringLiteral("Unit 1"));
    QCOMPARE(p.startDate.date(), date(10));
    QCOMPARE(p.startDate.time(), QTime(1, 0));   // 3600 s = 01:00
    QCOMPARE(p.endDate.date(),   date(10));
    QCOMPARE(p.endDate.time(),   QTime(2, 0));   // 7200 s = 02:00
}

void TestSqlPlanDatabase::addPlan_withRoutes_routesAreStored()
{
    m_db->addPlan("Routed Plan", date(10), 0, date(10), 3600, 2, {1, 3});

    const Plan p = firstPlanOnDay(10);
    QCOMPARE(p.routeIds.size(), 2);
    QVERIFY(p.routeIds.contains(1));
    QVERIFY(p.routeIds.contains(3));
}

void TestSqlPlanDatabase::addPlan_emitsPlansChanged()
{
    QSignalSpy spy(m_db, &SqlPlanDatabase::plansChanged);
    m_db->addPlan("P", date(10), 0, date(10), 3600, 1, {});
    QCOMPARE(spy.count(), 1);
}

// ── plansForRange — overlap semantics ────────────────────────────────────────

void TestSqlPlanDatabase::plansForRange_planOnExactDay()
{
    m_db->addPlan("P", date(15), 0, date(15), 3600, 1, {});
    QCOMPARE(m_db->plansForRange(date(15), date(15)).size(), 1);
}

void TestSqlPlanDatabase::plansForRange_planOutsideRange_notReturned()
{
    m_db->addPlan("Before", date(5),  0, date(5),  3600, 1, {});
    m_db->addPlan("After",  date(20), 0, date(20), 3600, 1, {});
    QCOMPARE(m_db->plansForRange(date(10), date(15)).size(), 0);
}

void TestSqlPlanDatabase::plansForRange_multiDayPlan_appearsOnAllOverlappingDays()
{
    // Plan spans day 10–12
    m_db->addPlan("Multi", date(10), 0, date(12), 0, 1, {});

    QCOMPARE(m_db->plansForRange(date(10), date(10)).size(), 1);
    QCOMPARE(m_db->plansForRange(date(11), date(11)).size(), 1);
    QCOMPARE(m_db->plansForRange(date(12), date(12)).size(), 1);
    QCOMPARE(m_db->plansForRange(date(13), date(13)).size(), 0);
    QCOMPARE(m_db->plansForRange(date(9),  date(9)).size(),  0);
}

void TestSqlPlanDatabase::plansForRange_unitFilter_restrictsResults()
{
    m_db->addPlan("U1 Plan", date(10), 0, date(10), 3600, 1, {});
    m_db->addPlan("U2 Plan", date(10), 0, date(10), 3600, 2, {});

    m_db->setUnitFilter({1});
    QCOMPARE(m_db->plansForRange(date(10), date(10)).size(), 1);
    QCOMPARE(m_db->plansForRange(date(10), date(10)).first().unitId, 1);

    m_db->setUnitFilter({});
    QCOMPARE(m_db->plansForRange(date(10), date(10)).size(), 2);
}

// ── updatePlan ────────────────────────────────────────────────────────────────

void TestSqlPlanDatabase::updatePlan_updatesFieldsAndRoutes()
{
    m_db->addPlan("Original", date(10), 0, date(10), 3600, 1, {1});
    const int id = firstPlanOnDay(10).id;

    m_db->updatePlan(id, "Updated", date(11), 7200, date(11), 10800, 2, {2, 3});

    const Plan p = firstPlanOnDay(11);
    QCOMPARE(p.id,       id);
    QCOMPARE(p.name,     QStringLiteral("Updated"));
    QCOMPARE(p.unitId,   2);
    QCOMPARE(p.startDate.date(), date(11));
    QCOMPARE(p.startDate.time(), QTime(2, 0));

    QCOMPARE(p.routeIds.size(), 2);
    QVERIFY(p.routeIds.contains(2));
    QVERIFY(p.routeIds.contains(3));
    QVERIFY(!p.routeIds.contains(1));  // old route removed
}

// ── deletePlan ────────────────────────────────────────────────────────────────

void TestSqlPlanDatabase::deletePlan_removesFromDatabase()
{
    m_db->addPlan("ToDelete", date(10), 0, date(10), 3600, 1, {});
    const int id = firstPlanOnDay(10).id;

    QVERIFY(m_db->deletePlan(id));
    QCOMPARE(m_db->plansForRange(date(10), date(10)).size(), 0);
}

void TestSqlPlanDatabase::deletePlan_cascadesRouteDeletion()
{
    // After deletion the plan should be gone; we verify by re-adding and checking
    // that route count for a clean add is correct (no ghost rows from the deleted plan).
    m_db->addPlan("P", date(10), 0, date(10), 3600, 1, {1, 2});
    const int id = firstPlanOnDay(10).id;
    m_db->deletePlan(id);

    m_db->addPlan("P2", date(10), 0, date(10), 3600, 1, {3});
    QCOMPARE(firstPlanOnDay(10).routeIds.size(), 1);
    QVERIFY(firstPlanOnDay(10).routeIds.contains(3));
}

// ── plannedHoursPerUnit ───────────────────────────────────────────────────────

void TestSqlPlanDatabase::plannedHoursPerUnit_correctHoursForSinglePlan()
{
    // 3600 s start, 10800 s end → 2 hours
    m_db->addPlan("P", date(10), 3600, date(10), 10800, 1, {});

    const QVariantList result = m_db->plannedHoursPerUnit(date(10), date(10));
    // Unit 1 should have 2 h
    const auto unit1 = result[0].toMap();
    QCOMPARE(unit1["unitId"].toInt(),    1);
    QCOMPARE(unit1["hours"].toDouble(),  2.0);
}

void TestSqlPlanDatabase::plannedHoursPerUnit_multiDayPlan_correctTotalHours()
{
    // Day 10 00:00 → Day 12 00:00 = 48 h
    m_db->addPlan("Multi", date(10), 0, date(12), 0, 2, {});

    const QVariantList result = m_db->plannedHoursPerUnit(date(1), date(30));
    const auto unit2 = result[1].toMap();
    QCOMPARE(unit2["unitId"].toInt(), 2);
    QCOMPARE(unit2["hours"].toDouble(), 48.0);
}

void TestSqlPlanDatabase::plannedHoursPerUnit_allUnitsAppearsEvenWithZeroHours()
{
    // No plans added — every unit should still appear with 0 h.
    const QVariantList result = m_db->plannedHoursPerUnit(date(1), date(30));
    QCOMPARE(result.size(), 3);
    for (const QVariant &row : result)
        QCOMPARE(row.toMap()["hours"].toDouble(), 0.0);
}

void TestSqlPlanDatabase::plannedHoursPerUnit_unitFilter_restrictsUnits()
{
    m_db->addPlan("U1", date(10), 0, date(10), 3600, 1, {});
    m_db->addPlan("U2", date(10), 0, date(10), 7200, 2, {});

    m_db->setUnitFilter({2});
    const QVariantList result = m_db->plannedHoursPerUnit(date(10), date(10));

    QCOMPARE(result.size(), 1);
    QCOMPARE(result[0].toMap()["unitId"].toInt(), 2);

    m_db->setUnitFilter({});
}

// ── unitFilter property ───────────────────────────────────────────────────────

void TestSqlPlanDatabase::unitFilter_setFilter_emitsSignals()
{
    QSignalSpy changedSpy(m_db, &SqlPlanDatabase::plansChanged);
    QSignalSpy filterSpy(m_db,  &SqlPlanDatabase::unitFilterChanged);

    m_db->setUnitFilter({1, 2});

    QCOMPARE(changedSpy.count(), 1);
    QCOMPARE(filterSpy.count(),  1);
    QCOMPARE(m_db->unitFilter().size(), 2);
}

void TestSqlPlanDatabase::unitFilter_clearFilter_showsAllPlans()
{
    m_db->addPlan("U1", date(10), 0, date(10), 3600, 1, {});
    m_db->addPlan("U2", date(10), 0, date(10), 3600, 2, {});
    m_db->addPlan("U3", date(10), 0, date(10), 3600, 3, {});

    m_db->setUnitFilter({1});
    QCOMPARE(m_db->plansForRange(date(10), date(10)).size(), 1);

    m_db->setUnitFilter({});
    QCOMPARE(m_db->plansForRange(date(10), date(10)).size(), 3);
}

// ── planById ─────────────────────────────────────────────────────────────────

void TestSqlPlanDatabase::planById_existingPlan_returnsCorrectData()
{
    m_db->addPlan("ById", date(10), 3600, date(10), 7200, 2, {1, 4});
    const int id = firstPlanOnDay(10).id;

    const Plan p = m_db->planById(id);
    QCOMPARE(p.id,       id);
    QCOMPARE(p.name,     QStringLiteral("ById"));
    QCOMPARE(p.unitId,   2);
    QCOMPARE(p.startDate.time(), QTime(1, 0));
    QCOMPARE(p.endDate.time(),   QTime(2, 0));
    QCOMPARE(p.routeIds.size(),  2);
    QVERIFY(p.routeIds.contains(1));
    QVERIFY(p.routeIds.contains(4));
}

void TestSqlPlanDatabase::planById_missingPlan_returnsInvalidPlan()
{
    const Plan p = m_db->planById(99999);
    QCOMPARE(p.id, -1);   // default-constructed Plan has id == -1
    QVERIFY(p.name.isEmpty());
}

// ── plansForRangeQML ─────────────────────────────────────────────────────────

void TestSqlPlanDatabase::plansForRangeQML_shape()
{
    m_db->addPlan("QML Plan", date(10), 3600, date(10), 7200, 1, {2, 3});

    const QVariantList list = m_db->plansForRangeQML(date(10), date(10));
    QCOMPARE(list.size(), 1);

    const QVariantMap m = list.first().toMap();
    QVERIFY(m.contains(QStringLiteral("planId")));
    QVERIFY(m.contains(QStringLiteral("startDate")));
    QVERIFY(m.contains(QStringLiteral("endDate")));
    QVERIFY(m.contains(QStringLiteral("unitId")));
    QVERIFY(m.contains(QStringLiteral("unitName")));
    QVERIFY(m.contains(QStringLiteral("routeIds")));
    QVERIFY(m.contains(QStringLiteral("routeNames")));

    QCOMPARE(m[QStringLiteral("unitId")].toInt(),      1);
    QCOMPARE(m[QStringLiteral("unitName")].toString(), QStringLiteral("Unit 1"));

    const QVariantList rids = m[QStringLiteral("routeIds")].toList();
    QCOMPARE(rids.size(), 2);
}

// ── setUnits / setRoutes ──────────────────────────────────────────────────────

void TestSqlPlanDatabase::setUnits_replacesExistingUnit()
{
    QSignalSpy spy(m_db, &SqlPlanDatabase::plansChanged);

    QVariantList updated;
    updated << QVariantMap{{QStringLiteral("id"), 1}, {QStringLiteral("name"), QStringLiteral("Alpha")}};
    m_db->setUnits(updated);

    QCOMPARE(spy.count(), 1);   // emits plansChanged so callers refresh

    const QVariantList units = m_db->allUnits();
    // id 1 should now be "Alpha"
    bool found = false;
    for (const QVariant &v : units) {
        const QVariantMap u = v.toMap();
        if (u[QStringLiteral("id")].toInt() == 1) {
            QCOMPARE(u[QStringLiteral("name")].toString(), QStringLiteral("Alpha"));
            found = true;
        }
    }
    QVERIFY(found);
}

void TestSqlPlanDatabase::setRoutes_replacesExistingRoute()
{
    QVariantList updated;
    updated << QVariantMap{{QStringLiteral("id"), 1}, {QStringLiteral("name"), QStringLiteral("New Route A")}};
    m_db->setRoutes(updated);

    const QVariantList routes = m_db->allRoutes();
    bool found = false;
    for (const QVariant &v : routes) {
        const QVariantMap r = v.toMap();
        if (r[QStringLiteral("id")].toInt() == 1) {
            QCOMPARE(r[QStringLiteral("name")].toString(), QStringLiteral("New Route A"));
            found = true;
        }
    }
    QVERIFY(found);
}

// ── applyRemotePlan / applyRemoteDelete ───────────────────────────────────────

void TestSqlPlanDatabase::applyRemotePlan_insertsNewPlan()
{
    m_db->applyRemotePlan(500, "Remote Plan", date(10), 3600, date(10), 7200, 1, {2});

    const Plan p = m_db->planById(500);
    QCOMPARE(p.id,   500);
    QCOMPARE(p.name, QStringLiteral("Remote Plan"));
    QCOMPARE(p.unitId, 1);
    QCOMPARE(p.routeIds.size(), 1);
    QVERIFY(p.routeIds.contains(2));
}

void TestSqlPlanDatabase::applyRemotePlan_updatesExistingPlan()
{
    m_db->applyRemotePlan(501, "Original",  date(10), 0, date(10), 3600, 1, {1});
    m_db->applyRemotePlan(501, "Updated",   date(11), 0, date(11), 7200, 2, {3, 4});

    const Plan p = m_db->planById(501);
    QCOMPARE(p.name,   QStringLiteral("Updated"));
    QCOMPARE(p.unitId, 2);
    QCOMPARE(p.startDate.date(), date(11));
    QCOMPARE(p.routeIds.size(),  2);
    QVERIFY(!p.routeIds.contains(1));  // old route replaced
}

void TestSqlPlanDatabase::applyRemotePlan_doesNotEmitPlanAdded()
{
    QSignalSpy addedSpy(m_db,   &SqlPlanDatabase::planAdded);
    QSignalSpy changedSpy(m_db, &SqlPlanDatabase::plansChanged);

    m_db->applyRemotePlan(502, "Remote", date(10), 0, date(10), 3600, 1, {});

    QCOMPARE(addedSpy.count(),   0);   // must not trigger push-back to server
    QCOMPARE(changedSpy.count(), 1);   // UI must still refresh
}

void TestSqlPlanDatabase::applyRemoteDelete_removesPlan()
{
    m_db->applyRemotePlan(503, "ToRemove", date(10), 0, date(10), 3600, 1, {});
    m_db->applyRemoteDelete(503);

    const Plan p = m_db->planById(503);
    QVERIFY(p.name.isEmpty());
    QCOMPARE(m_db->plansForRange(date(10), date(10)).size(), 0);
}

void TestSqlPlanDatabase::applyRemoteDelete_doesNotEmitPlanDeleted()
{
    m_db->applyRemotePlan(504, "ToRemote", date(10), 0, date(10), 3600, 1, {});

    QSignalSpy deletedSpy(m_db, &SqlPlanDatabase::planDeleted);
    QSignalSpy changedSpy(m_db, &SqlPlanDatabase::plansChanged);

    m_db->applyRemoteDelete(504);

    QCOMPARE(deletedSpy.count(), 0);   // must not trigger push-back to server
    QCOMPARE(changedSpy.count(), 1);   // UI must still refresh
}

QTEST_MAIN(TestSqlPlanDatabase)
#include "tst_sqlplandatabase.moc"
