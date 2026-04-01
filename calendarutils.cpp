// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "calendarutils.h"

#include <QDateTime>
#include <QHash>
#include <QVariantMap>

#include <algorithm>

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

QVariantList CalendarUtils::buildWeekGrid(const QVariantList &units,
                                           const QVariantList &plans,
                                           QDate weekStart) const
{
    struct PlanEntry {
        QVariantMap map;
        int startDi; // day index within week [0..6]
        int endDi;
    };

    // Annotate each plan with its day range within the week
    QList<PlanEntry> entries;
    entries.reserve(plans.size());
    for (const QVariant &v : plans) {
        const QVariantMap m = v.toMap();
        const QDate pd = m[QStringLiteral("startDate")].toDateTime().date();
        const QDate ed = m[QStringLiteral("endDate")].toDateTime().date();
        const int startDi = std::max(0, static_cast<int>(weekStart.daysTo(pd)));
        const int endDi   = std::min(6, static_cast<int>(weekStart.daysTo(ed)));
        entries.push_back({m, startDi, endDi});
    }

    // Group unique plans per unit (deduplicate multi-day plans that appear
    // multiple times in plansForRangeQML output by using planId as key)
    QHash<int, QHash<int, PlanEntry>> byUnit;
    for (const QVariant &uv : units)
        byUnit[uv.toMap()[QStringLiteral("id")].toInt()] = {};
    for (const PlanEntry &e : entries) {
        const int uid = e.map[QStringLiteral("unitId")].toInt();
        const int pid = e.map[QStringLiteral("planId")].toInt();
        if (byUnit.contains(uid))
            byUnit[uid][pid] = e;
    }

    QVariantList rows;
    for (const QVariant &uv : units) {
        const QVariantMap um = uv.toMap();
        const int uid = um[QStringLiteral("id")].toInt();

        QVariantMap headerRow;
        headerRow[QStringLiteral("rowType")]  = QStringLiteral("header");
        headerRow[QStringLiteral("unitId")]   = uid;
        headerRow[QStringLiteral("unitName")] = um[QStringLiteral("name")];
        rows << headerRow;

        // Collect and sort plans: by startDi, then endDi
        QList<PlanEntry> unitPlans;
        for (const PlanEntry &e : byUnit[uid])
            unitPlans.push_back(e);
        std::sort(unitPlans.begin(), unitPlans.end(), [](const PlanEntry &a, const PlanEntry &b) {
            return a.startDi < b.startDi || (a.startDi == b.startDi && a.endDi < b.endDi);
        });

        // Greedy interval scheduling: each plan goes in the first slot where it
        // doesn't overlap the last plan already placed (slots are sorted by startDi)
        QList<QList<PlanEntry>> slots;
        for (const PlanEntry &plan : unitPlans) {
            bool placed = false;
            for (auto &slot : slots) {
                if (plan.startDi > slot.last().endDi) {
                    slot.push_back(plan);
                    placed = true;
                    break;
                }
            }
            if (!placed)
                slots.push_back({plan});
        }

        const int numSlots = std::max(1, static_cast<int>(slots.size()));
        for (int s = 0; s < numSlots; s++) {
            QVariantList dayPlans;
            for (int d = 0; d < 7; d++)
                dayPlans << QVariant(); // null = empty cell

            if (s < slots.size()) {
                for (const PlanEntry &plan : slots.at(s)) {
                    for (int d = plan.startDi; d <= plan.endDi; d++)
                        dayPlans[d] = plan.map;
                }
            }

            QVariantMap planRow;
            planRow[QStringLiteral("rowType")]   = QStringLiteral("plan");
            planRow[QStringLiteral("unitId")]    = uid;
            planRow[QStringLiteral("slotIndex")] = s;
            planRow[QStringLiteral("dayPlans")]  = dayPlans;
            rows << planRow;
        }
    }

    return rows;
}
