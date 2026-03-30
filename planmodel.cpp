#include "planmodel.h"
#include "sqlplandatabase.h"

#include <QtCore/QScopeGuard>

PlanModel::PlanModel(QObject *parent)
    : QAbstractListModel(parent)
{}

SqlPlanDatabase *PlanModel::planDatabase()
{
    return m_planDatabase;
}

void PlanModel::setPlanDatabase(SqlPlanDatabase *db)
{
    if (db == m_planDatabase)
        return;

    if (m_planDatabase)
        disconnect(m_planDatabase, &SqlPlanDatabase::plansChanged, this, &PlanModel::repopulate);

    m_planDatabase = db;

    if (m_planDatabase)
        connect(m_planDatabase, &SqlPlanDatabase::plansChanged, this, &PlanModel::repopulate);

    repopulate();
    emit planDatabaseChanged();
}

QDate PlanModel::date() const { return m_date; }

void PlanModel::setDate(QDate date)
{
    if (date == m_date)
        return;
    m_date = date;
    repopulate();
    emit dateChanged();
}

QDate PlanModel::endDate() const { return m_endDate; }

void PlanModel::setEndDate(QDate date)
{
    if (date == m_endDate)
        return;
    m_endDate = date;
    repopulate();
    emit endDateChanged();
}

int PlanModel::rowCount(const QModelIndex &) const
{
    return m_plans.size();
}

QVariant PlanModel::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::IndexIsValid))
        return QVariant();

    const Plan &p = m_plans.at(index.row());
    switch (role) {
    case IdRole:        return p.id;
    case NameRole:      return p.name;
    case StartDateRole: return p.startDate;
    case EndDateRole:   return p.endDate;
    case UnitIdRole:    return p.unitId;
    case UnitNameRole:  return p.unitName;
    case RouteIdsRole: {
        QVariantList ids;
        ids.reserve(p.routeIds.size());
        for (int id : p.routeIds) ids.append(id);
        return ids;
    }
    default: return QVariant();
    }
}

QHash<int, QByteArray> PlanModel::roleNames() const
{
    static const QHash<int, QByteArray> roles {
        { IdRole,        "planId"    },
        { NameRole,      "name"      },
        { StartDateRole, "startDate" },
        { EndDateRole,   "endDate"   },
        { UnitIdRole,    "unitId"    },
        { UnitNameRole,  "unitName"  },
        { RouteIdsRole,  "routeIds"  }
    };
    return roles;
}

void PlanModel::repopulate()
{
    beginResetModel();
    auto endReset = qScopeGuard([this]{ endResetModel(); });

    if (!m_planDatabase || m_date.isNull()) {
        m_plans.clear();
        return;
    }

    const QDate end = m_endDate.isNull() ? m_date : m_endDate;
    m_plans = m_planDatabase->plansForRange(m_date, end);
}
