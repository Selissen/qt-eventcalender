// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QtTest>
#include "planmodel.h"
#include "sqlplandatabase.h"

class TestPlanModel : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();

    void rowCount_noDatabase_isZero();
    void rowCount_withPlans_matchesDatabase();

    void data_allRolesReturnCorrectValues();

    void setDate_triggersRepopulate();
    void setEndDate_expandsRangeToIncludeMorePlans();

    void databaseChanged_repopulatesModel();
    void planDeleted_modelShrinks();

private:
    SqlPlanDatabase *m_db    = nullptr;
    PlanModel       *m_model = nullptr;

    static constexpr int kYear  = 2026;
    static constexpr int kMonth = 6;

    QDate date(int day) const { return {kYear, kMonth, day}; }
};

// ── Fixture ───────────────────────────────────────────────────────────────────

void TestPlanModel::init()
{
    m_db    = new SqlPlanDatabase("test_planmodel_db", /*withSampleData=*/false, this);
    m_model = new PlanModel(this);
    m_model->setPlanDatabase(m_db);
}

void TestPlanModel::cleanup()
{
    delete m_model;
    delete m_db;
    m_model = nullptr;
    m_db    = nullptr;
}

// ── rowCount ──────────────────────────────────────────────────────────────────

void TestPlanModel::rowCount_noDatabase_isZero()
{
    PlanModel empty;
    QCOMPARE(empty.rowCount(), 0);
}

void TestPlanModel::rowCount_withPlans_matchesDatabase()
{
    m_db->addPlan("A", date(10), 0, date(10), 3600, 1, {});
    m_db->addPlan("B", date(10), 0, date(10), 7200, 2, {});

    m_model->setDate(date(10));
    QCOMPARE(m_model->rowCount(), 2);
}

// ── data roles ────────────────────────────────────────────────────────────────

void TestPlanModel::data_allRolesReturnCorrectValues()
{
    m_db->addPlan("Plan X", date(15), 3600, date(15), 7200, 1, {2, 3});
    m_model->setDate(date(15));

    QCOMPARE(m_model->rowCount(), 1);
    const QModelIndex idx = m_model->index(0);

    QCOMPARE(m_model->data(idx, PlanModel::NameRole).toString(),  QStringLiteral("Plan X"));
    QCOMPARE(m_model->data(idx, PlanModel::UnitIdRole).toInt(),   1);
    QCOMPARE(m_model->data(idx, PlanModel::UnitNameRole).toString(), QStringLiteral("Unit 1"));

    const QVariantList routeIds = m_model->data(idx, PlanModel::RouteIdsRole).toList();
    QCOMPARE(routeIds.size(), 2);
    QVERIFY(routeIds.contains(2));
    QVERIFY(routeIds.contains(3));

    const QDateTime startDt = m_model->data(idx, PlanModel::StartDateRole).toDateTime();
    QCOMPARE(startDt.date(), date(15));
    QCOMPARE(startDt.time(), QTime(1, 0));  // 3600 s = 01:00

    QVERIFY(m_model->data(idx, PlanModel::IdRole).toInt() > 0);
}

// ── setDate / setEndDate ──────────────────────────────────────────────────────

void TestPlanModel::setDate_triggersRepopulate()
{
    m_db->addPlan("P", date(10), 0, date(10), 3600, 1, {});

    m_model->setDate(date(5));
    QCOMPARE(m_model->rowCount(), 0);

    m_model->setDate(date(10));
    QCOMPARE(m_model->rowCount(), 1);
}

void TestPlanModel::setEndDate_expandsRangeToIncludeMorePlans()
{
    m_db->addPlan("Day10", date(10), 0, date(10), 3600, 1, {});
    m_db->addPlan("Day15", date(15), 0, date(15), 3600, 1, {});

    m_model->setDate(date(10));
    QCOMPARE(m_model->rowCount(), 1);  // only day 10

    m_model->setEndDate(date(15));
    QCOMPARE(m_model->rowCount(), 2);  // day 10 and day 15
}

// ── reactivity ───────────────────────────────────────────────────────────────

void TestPlanModel::databaseChanged_repopulatesModel()
{
    m_model->setDate(date(10));
    QCOMPARE(m_model->rowCount(), 0);

    m_db->addPlan("P", date(10), 0, date(10), 3600, 1, {});
    // addPlan emits plansChanged, which triggers repopulate
    QCOMPARE(m_model->rowCount(), 1);
}

void TestPlanModel::planDeleted_modelShrinks()
{
    m_db->addPlan("P", date(10), 0, date(10), 3600, 1, {});
    m_model->setDate(date(10));
    QCOMPARE(m_model->rowCount(), 1);

    const int id = m_model->data(m_model->index(0), PlanModel::IdRole).toInt();
    m_db->deletePlan(id);
    QCOMPARE(m_model->rowCount(), 0);
}

QTEST_MAIN(TestPlanModel)
#include "tst_planmodel.moc"
