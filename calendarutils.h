// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef CALENDARUTILS_H
#define CALENDARUTILS_H

#include <QDate>
#include <QObject>
#include <QVariantList>
#include <QtQml>

class CalendarUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit CalendarUtils(QObject *parent = nullptr);

    // Returns the ISO 8601 week number for the given date.
    Q_INVOKABLE int isoWeekNumber(QDate date) const;

    // Returns the first day of the week containing date.
    // firstDayOfWeek uses QML / JS convention: 0 = Sunday, 1 = Monday … 6 = Saturday,
    // matching Qt.locale().firstDayOfWeek as returned in QML.
    Q_INVOKABLE QDate weekStart(QDate date, int firstDayOfWeek) const;

    // Returns the date one step earlier (7 days in week view, 1 month in month view).
    Q_INVOKABLE QDate navigatePrev(QDate date, bool weekView) const;

    // Returns the date one step later (7 days in week view, 1 month in month view).
    Q_INVOKABLE QDate navigateNext(QDate date, bool weekView) const;

    // Builds the flat row array for WeekView from pre-fetched data.
    //
    // units  — QVariantList of { id: int, name: string }  (already filtered)
    // plans  — QVariantList in plansForRangeQML() shape
    // weekStart — first day of the displayed week
    //
    // Returns a QVariantList whose entries are either:
    //   { rowType:"header", unitId, unitName }
    //   { rowType:"plan",   unitId, slotIndex, dayPlans:[plan|null × 7] }
    Q_INVOKABLE QVariantList buildWeekGrid(const QVariantList &units,
                                           const QVariantList &plans,
                                           QDate weekStart) const;
};

#endif // CALENDARUTILS_H
