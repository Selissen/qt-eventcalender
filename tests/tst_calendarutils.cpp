// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QtTest>
#include "calendarutils.h"

class TestCalendarUtils : public QObject
{
    Q_OBJECT

private slots:
    void isoWeekNumber_knownDates();
    void isoWeekNumber_yearBoundary();
    void isoWeekNumber_yearWith53Weeks();

    void weekStart_mondayFirst();
    void weekStart_sundayFirst();
    void weekStart_alreadyOnFirstDay();
    void weekStart_crossesMonthBoundary();

    void navigatePrev_weekView();
    void navigatePrev_monthView();
    void navigatePrev_monthView_clampsToLastDay();
    void navigatePrev_crossesYearBoundary();

    void navigateNext_weekView();
    void navigateNext_monthView();
    void navigateNext_monthView_clampsToLastDay();
    void navigateNext_crossesYearBoundary();
};

// ---------------------------------------------------------------------------
// isoWeekNumber
// ---------------------------------------------------------------------------

void TestCalendarUtils::isoWeekNumber_knownDates()
{
    CalendarUtils utils;
    // 2026-01-01 is a Thursday → week 1
    QCOMPARE(utils.isoWeekNumber(QDate(2026, 1, 1)), 1);
    // Week 13 of 2026: Mon 2026-03-23 … Sun 2026-03-29
    QCOMPARE(utils.isoWeekNumber(QDate(2026, 3, 23)), 13); // Monday
    QCOMPARE(utils.isoWeekNumber(QDate(2026, 3, 27)), 13); // Friday
    QCOMPARE(utils.isoWeekNumber(QDate(2026, 3, 29)), 13); // Sunday
    QCOMPARE(utils.isoWeekNumber(QDate(2026, 3, 30)), 14); // Monday of week 14
}

void TestCalendarUtils::isoWeekNumber_yearBoundary()
{
    CalendarUtils utils;
    // 2025-12-28 (Sun) is the last day of week 52 of 2025
    QCOMPARE(utils.isoWeekNumber(QDate(2025, 12, 28)), 52);
    // 2025-12-29 (Mon) starts week 1 of 2026
    QCOMPARE(utils.isoWeekNumber(QDate(2025, 12, 29)), 1);
}

void TestCalendarUtils::isoWeekNumber_yearWith53Weeks()
{
    CalendarUtils utils;
    // 2026 starts on Thursday → it has 53 ISO weeks
    QCOMPARE(utils.isoWeekNumber(QDate(2026, 12, 28)), 53); // Monday of week 53
    QCOMPARE(utils.isoWeekNumber(QDate(2026, 12, 31)), 53); // Thursday, still week 53
}

// ---------------------------------------------------------------------------
// weekStart — firstDayOfWeek uses QML/JS scale: 0 = Sunday, 1 = Monday … 6 = Saturday
// ---------------------------------------------------------------------------

void TestCalendarUtils::weekStart_mondayFirst()
{
    CalendarUtils utils;
    const int monday = 1;
    // 2026-03-27 is Friday → week start is Monday 2026-03-23
    QCOMPARE(utils.weekStart(QDate(2026, 3, 27), monday), QDate(2026, 3, 23));
    // 2026-03-29 is Sunday → week start is still Monday 2026-03-23
    QCOMPARE(utils.weekStart(QDate(2026, 3, 29), monday), QDate(2026, 3, 23));
    // 2026-03-24 is Tuesday → week start is Monday 2026-03-23
    QCOMPARE(utils.weekStart(QDate(2026, 3, 24), monday), QDate(2026, 3, 23));
}

void TestCalendarUtils::weekStart_sundayFirst()
{
    CalendarUtils utils;
    const int sunday = 0;
    // 2026-03-27 is Friday → week start is Sunday 2026-03-22
    QCOMPARE(utils.weekStart(QDate(2026, 3, 27), sunday), QDate(2026, 3, 22));
    // 2026-03-28 is Saturday → week start is still Sunday 2026-03-22
    QCOMPARE(utils.weekStart(QDate(2026, 3, 28), sunday), QDate(2026, 3, 22));
    // 2026-03-23 is Monday → week start is Sunday 2026-03-22
    QCOMPARE(utils.weekStart(QDate(2026, 3, 23), sunday), QDate(2026, 3, 22));
}

void TestCalendarUtils::weekStart_alreadyOnFirstDay()
{
    CalendarUtils utils;
    // Input already is the first day → returned unchanged
    QCOMPARE(utils.weekStart(QDate(2026, 3, 23), 1), QDate(2026, 3, 23)); // Monday, first=Mon
    QCOMPARE(utils.weekStart(QDate(2026, 3, 22), 0), QDate(2026, 3, 22)); // Sunday, first=Sun
}

void TestCalendarUtils::weekStart_crossesMonthBoundary()
{
    CalendarUtils utils;
    const int monday = 1;
    // 2026-03-03 is Tuesday → week start crosses back into February: 2026-03-02 Mon
    QCOMPARE(utils.weekStart(QDate(2026, 3, 3), monday), QDate(2026, 3, 2));
    // 2026-03-01 is Sunday → week start is 2026-02-23 Mon
    QCOMPARE(utils.weekStart(QDate(2026, 3, 1), monday), QDate(2026, 2, 23));
}

// ---------------------------------------------------------------------------
// navigatePrev
// ---------------------------------------------------------------------------

void TestCalendarUtils::navigatePrev_weekView()
{
    CalendarUtils utils;
    QCOMPARE(utils.navigatePrev(QDate(2026, 3, 27), true), QDate(2026, 3, 20));
    // Crosses month boundary
    QCOMPARE(utils.navigatePrev(QDate(2026, 3, 3),  true), QDate(2026, 2, 24));
}

void TestCalendarUtils::navigatePrev_monthView()
{
    CalendarUtils utils;
    QCOMPARE(utils.navigatePrev(QDate(2026, 3, 27), false), QDate(2026, 2, 27));
    QCOMPARE(utils.navigatePrev(QDate(2026, 6, 15), false), QDate(2026, 5, 15));
}

void TestCalendarUtils::navigatePrev_monthView_clampsToLastDay()
{
    CalendarUtils utils;
    // March 31 → February has no 31st, clamps to Feb 28
    QCOMPARE(utils.navigatePrev(QDate(2026, 3, 31), false), QDate(2026, 2, 28));
}

void TestCalendarUtils::navigatePrev_crossesYearBoundary()
{
    CalendarUtils utils;
    QCOMPARE(utils.navigatePrev(QDate(2026, 1, 15), false), QDate(2025, 12, 15));
}

// ---------------------------------------------------------------------------
// navigateNext
// ---------------------------------------------------------------------------

void TestCalendarUtils::navigateNext_weekView()
{
    CalendarUtils utils;
    QCOMPARE(utils.navigateNext(QDate(2026, 3, 27), true), QDate(2026, 4, 3));
    // Crosses year boundary
    QCOMPARE(utils.navigateNext(QDate(2026, 12, 28), true), QDate(2027, 1, 4));
}

void TestCalendarUtils::navigateNext_monthView()
{
    CalendarUtils utils;
    QCOMPARE(utils.navigateNext(QDate(2026, 3, 27), false), QDate(2026, 4, 27));
    QCOMPARE(utils.navigateNext(QDate(2026, 6, 15), false), QDate(2026, 7, 15));
}

void TestCalendarUtils::navigateNext_monthView_clampsToLastDay()
{
    CalendarUtils utils;
    // January 31 → February has no 31st, clamps to Feb 28
    QCOMPARE(utils.navigateNext(QDate(2026, 1, 31), false), QDate(2026, 2, 28));
}

void TestCalendarUtils::navigateNext_crossesYearBoundary()
{
    CalendarUtils utils;
    QCOMPARE(utils.navigateNext(QDate(2026, 12, 15), false), QDate(2027, 1, 15));
}

QTEST_MAIN(TestCalendarUtils)
#include "tst_calendarutils.moc"
