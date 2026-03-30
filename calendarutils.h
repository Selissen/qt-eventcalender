// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef CALENDARUTILS_H
#define CALENDARUTILS_H

#include <QDate>
#include <QObject>
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
};

#endif // CALENDARUTILS_H
