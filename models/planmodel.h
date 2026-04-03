#ifndef PLANMODEL_H
#define PLANMODEL_H

#include <QAbstractListModel>
#include <QDate>
#include <QtQml>

#include "plan.h"

class SqlPlanDatabase;

class PlanModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(SqlPlanDatabase *planDatabase READ planDatabase WRITE setPlanDatabase NOTIFY planDatabaseChanged)
    Q_PROPERTY(QDate date    READ date    WRITE setDate    NOTIFY dateChanged)
    Q_PROPERTY(QDate endDate READ endDate WRITE setEndDate NOTIFY endDateChanged)
    QML_ELEMENT
    Q_MOC_INCLUDE("sqlplandatabase.h")

public:
    explicit PlanModel(QObject *parent = nullptr);

    enum PlanRole {
        IdRole = Qt::UserRole,
        StartDateRole,
        EndDateRole,
        UnitIdRole,
        UnitNameRole,
        RouteIdsRole,
        RouteNamesRole
    };
    Q_ENUM(PlanRole)

    SqlPlanDatabase *planDatabase();
    void setPlanDatabase(SqlPlanDatabase *db);

    QDate date() const;
    void setDate(QDate date);

    QDate endDate() const;
    void setEndDate(QDate date);

    int rowCount(const QModelIndex & = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void planDatabaseChanged();
    void dateChanged();
    void endDateChanged();

private:
    void repopulate();

    SqlPlanDatabase *m_planDatabase = nullptr;
    QDate m_date;
    QDate m_endDate;
    QList<Plan> m_plans;
};

#endif // PLANMODEL_H
