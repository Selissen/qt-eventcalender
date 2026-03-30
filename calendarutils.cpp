// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "calendarutils.h"

CalendarUtils::CalendarUtils(QObject *parent) : QObject(parent) {}

int CalendarUtils::isoWeekNumber(QDate date) const
{
    return date.weekNumber();
}

QDate CalendarUtils::weekStart(QDate date, int firstDayOfWeek) const
{
    // QDate::dayOfWeek() uses Mon=1 … Sun=7.
    // Convert to the same 0-6 (Sun=0, Mon=1 … Sat=6) scale used by QML / JS:
    //   dayOfWeek % 7  →  Mon=1, Tue=2, …, Sat=6, Sun=0
    int day = date.dayOfWeek() % 7;
    int diff = (day - firstDayOfWeek + 7) % 7;
    return date.addDays(-diff);
}

QDate CalendarUtils::navigatePrev(QDate date, bool weekView) const
{
    return weekView ? date.addDays(-7) : date.addMonths(-1);
}

QDate CalendarUtils::navigateNext(QDate date, bool weekView) const
{
    return weekView ? date.addDays(7) : date.addMonths(1);
}
