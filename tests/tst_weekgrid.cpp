// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QtTest>
#include "calendarutils.h"

// Tests for CalendarUtils::buildWeekGrid().
//
// The function takes pre-fetched units/plans (same shapes as allUnits() /
// plansForRangeQML()) and returns the flat row array consumed by WeekView.
// This avoids the need for a QML engine or a live database in these tests.

class TestWeekGrid : public QObject
{
    Q_OBJECT

private slots:
    void noPlans_oneHeaderAndOneEmptyPlanRowPerUnit();
    void singlePlan_placedOnCorrectDay();
    void multiDayPlan_fillsMultipleCells();
    void nonOverlappingPlans_bothInSlot0();
    void overlappingPlans_assignedToDifferentSlots();
    void threeWayOverlap_threeSlotsCreated();
    void unitFilter_onlyRequestedUnitsAppear();
    void planOutsideWeek_doesNotAppear();
    void emptyUnits_returnsEmptyList();

private:
    CalendarUtils m_cu;

    // Monday 2026-06-01  (first day of a convenient test week)
    static const QDate kWeekStart;

    // Build a minimal unit map  { id, name }
    static QVariantMap unit(int id, const QString &name)
    {
        return {{QStringLiteral("id"), id}, {QStringLiteral("name"), name}};
    }

    // Build a minimal plan map in plansForRangeQML() shape
    static QVariantMap plan(int planId, int unitId, QDate start, QDate end)
    {
        return {
            {QStringLiteral("planId"),   planId},
            {QStringLiteral("name"),     QStringLiteral("P") + QString::number(planId)},
            {QStringLiteral("unitId"),   unitId},
            {QStringLiteral("unitName"), QStringLiteral("Unit")},
            {QStringLiteral("startDate"), QDateTime(start, QTime(8, 0))},
            {QStringLiteral("endDate"),   QDateTime(end,   QTime(9, 0))},
            {QStringLiteral("routeIds"),  QVariantList{}},
        };
    }

    // Extract the row type from a row variant
    static QString rowType(const QVariant &row) { return row.toMap()[QStringLiteral("rowType")].toString(); }
    static QVariantList dayPlans(const QVariant &row) { return row.toMap()[QStringLiteral("dayPlans")].toList(); }
    static bool cellEmpty(const QVariant &cell) { return !cell.isValid() || cell.isNull(); }
    static int  cellPlanId(const QVariant &cell) { return cell.toMap()[QStringLiteral("planId")].toInt(); }
};

const QDate TestWeekGrid::kWeekStart{2026, 6, 1}; // Monday

// ── Tests ──────────────────────────────────────────────────────────────────────

void TestWeekGrid::noPlans_oneHeaderAndOneEmptyPlanRowPerUnit()
{
    const QVariantList units = {unit(1, "A"), unit(2, "B")};
    const QVariantList rows  = m_cu.buildWeekGrid(units, {}, kWeekStart);

    // 2 units × (1 header + 1 plan row) = 4 rows
    QCOMPARE(rows.size(), 4);
    QCOMPARE(rowType(rows[0]), QStringLiteral("header"));
    QCOMPARE(rowType(rows[1]), QStringLiteral("plan"));
    QCOMPARE(rowType(rows[2]), QStringLiteral("header"));
    QCOMPARE(rowType(rows[3]), QStringLiteral("plan"));

    // All 7 day cells in each plan row should be empty
    for (const QVariant &cell : dayPlans(rows[1]))
        QVERIFY(cellEmpty(cell));
}

void TestWeekGrid::singlePlan_placedOnCorrectDay()
{
    // Plan on Wednesday (day index 2 of a Mon-starting week)
    const QDate wednesday = kWeekStart.addDays(2);
    const QVariantList units = {unit(1, "A")};
    const QVariantList plans = {plan(10, 1, wednesday, wednesday)};
    const QVariantList rows  = m_cu.buildWeekGrid(units, plans, kWeekStart);

    // rows: [header, planRow]
    QCOMPARE(rows.size(), 2);
    const QVariantList dp = dayPlans(rows[1]);
    QVERIFY(cellEmpty(dp[0]));   // Mon
    QVERIFY(cellEmpty(dp[1]));   // Tue
    QCOMPARE(cellPlanId(dp[2]), 10);  // Wed ✓
    QVERIFY(cellEmpty(dp[3]));   // Thu
}

void TestWeekGrid::multiDayPlan_fillsMultipleCells()
{
    // Plan spans Mon (0) through Thu (3)
    const QVariantList units = {unit(1, "A")};
    const QVariantList plans = {plan(20, 1, kWeekStart, kWeekStart.addDays(3))};
    const QVariantList rows  = m_cu.buildWeekGrid(units, plans, kWeekStart);

    const QVariantList dp = dayPlans(rows[1]);
    for (int d = 0; d <= 3; d++)
        QCOMPARE(cellPlanId(dp[d]), 20);
    for (int d = 4; d <= 6; d++)
        QVERIFY(cellEmpty(dp[d]));
}

void TestWeekGrid::nonOverlappingPlans_bothInSlot0()
{
    // Plan A: Mon–Tue, Plan B: Thu–Fri — no overlap → same slot
    const QVariantList units = {unit(1, "A")};
    const QVariantList plans = {
        plan(1, 1, kWeekStart,            kWeekStart.addDays(1)),   // Mon–Tue
        plan(2, 1, kWeekStart.addDays(3), kWeekStart.addDays(4)),   // Thu–Fri
    };
    const QVariantList rows = m_cu.buildWeekGrid(units, plans, kWeekStart);

    // header + exactly 1 plan row (both plans fit in slot 0)
    QCOMPARE(rows.size(), 2);
    const QVariantList dp = dayPlans(rows[1]);
    QCOMPARE(cellPlanId(dp[0]), 1);   // Mon
    QCOMPARE(cellPlanId(dp[1]), 1);   // Tue
    QVERIFY(cellEmpty(dp[2]));        // Wed
    QCOMPARE(cellPlanId(dp[3]), 2);   // Thu
    QCOMPARE(cellPlanId(dp[4]), 2);   // Fri
}

void TestWeekGrid::overlappingPlans_assignedToDifferentSlots()
{
    // Plan A: Mon–Wed, Plan B: Tue–Thu — overlap → different slots
    const QVariantList units = {unit(1, "A")};
    const QVariantList plans = {
        plan(1, 1, kWeekStart,            kWeekStart.addDays(2)),   // Mon–Wed
        plan(2, 1, kWeekStart.addDays(1), kWeekStart.addDays(3)),   // Tue–Thu
    };
    const QVariantList rows = m_cu.buildWeekGrid(units, plans, kWeekStart);

    // header + 2 plan rows
    QCOMPARE(rows.size(), 3);
    QCOMPARE(rowType(rows[1]), QStringLiteral("plan"));
    QCOMPARE(rowType(rows[2]), QStringLiteral("plan"));

    // Slot 0 contains plan 1 (sorted by startDi first)
    QCOMPARE(cellPlanId(dayPlans(rows[1])[0]), 1);
    // Slot 1 contains plan 2
    QCOMPARE(cellPlanId(dayPlans(rows[2])[1]), 2);
}

void TestWeekGrid::threeWayOverlap_threeSlotsCreated()
{
    // Three plans all starting on Monday — all overlap
    const QVariantList units = {unit(1, "A")};
    const QVariantList plans = {
        plan(1, 1, kWeekStart, kWeekStart),
        plan(2, 1, kWeekStart, kWeekStart),
        plan(3, 1, kWeekStart, kWeekStart),
    };
    const QVariantList rows = m_cu.buildWeekGrid(units, plans, kWeekStart);

    // header + 3 plan rows
    QCOMPARE(rows.size(), 4);
    for (int r = 1; r <= 3; r++)
        QCOMPARE(rowType(rows[r]), QStringLiteral("plan"));
}

void TestWeekGrid::unitFilter_onlyRequestedUnitsAppear()
{
    // Pass only unit 2 — unit 1 plans should not produce rows
    const QVariantList units = {unit(2, "B")};
    const QVariantList plans = {
        plan(1, 1, kWeekStart, kWeekStart),   // unit 1 — excluded
        plan(2, 2, kWeekStart, kWeekStart),   // unit 2 — included
    };
    const QVariantList rows = m_cu.buildWeekGrid(units, plans, kWeekStart);

    // Only 1 unit's rows: header + plan row
    QCOMPARE(rows.size(), 2);
    QCOMPARE(rows[0].toMap()[QStringLiteral("unitId")].toInt(), 2);
    QCOMPARE(cellPlanId(dayPlans(rows[1])[0]), 2);
}

void TestWeekGrid::planOutsideWeek_doesNotAppear()
{
    // Plan is entirely in the following week — should not appear in any cell
    const QVariantList units = {unit(1, "A")};
    const QDate nextWeek = kWeekStart.addDays(7);
    const QVariantList plans = {plan(99, 1, nextWeek, nextWeek)};
    const QVariantList rows = m_cu.buildWeekGrid(units, plans, kWeekStart);

    // header + 1 empty plan row
    QCOMPARE(rows.size(), 2);
    for (const QVariant &cell : dayPlans(rows[1]))
        QVERIFY(cellEmpty(cell));
}

void TestWeekGrid::emptyUnits_returnsEmptyList()
{
    const QVariantList rows = m_cu.buildWeekGrid({}, {}, kWeekStart);
    QVERIFY(rows.isEmpty());
}

QTEST_MAIN(TestWeekGrid)
#include "tst_weekgrid.moc"
