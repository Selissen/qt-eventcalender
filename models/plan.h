#ifndef PLAN_H
#define PLAN_H

#include <QDateTime>
#include <QList>
#include <QString>

struct Plan {
    int id = -1;
    QString name;
    QDateTime startDate;
    QDateTime endDate;
    int unitId = -1;
    QString unitName;
    QList<int> routeIds;
    QStringList routeNames;
};

#endif // PLAN_H
