#include "grpcsyncbackend.h"
#include "sqlplandatabase.h"
#include "plan.h"

#include "calendar.qpb.h"
#include "calendar_client.grpc.qpb.h"

#include <QAbstractGrpcChannel>
#include <QGrpcServerStream>
#include <QDebug>

// ── Construction ──────────────────────────────────────────────────────────────

GrpcSyncBackend::GrpcSyncBackend(SqlPlanDatabase *db,
                                  std::shared_ptr<QAbstractGrpcChannel> channel,
                                  QObject *parent)
    : ISyncBackend(db, parent)
{
    m_client = new calendar::CalendarService::Client(this);
    m_client->attachChannel(std::move(channel));
}

// ── Helpers ───────────────────────────────────────────────────────────────────

static calendar::PlanData planToProto(const Plan &plan)
{
    calendar::PlanData data;
    data.setName(plan.name);
    data.setStartDate(plan.startDate.date().toString(Qt::ISODate));
    data.setStartTimeSecs(plan.startDate.time().msecsSinceStartOfDay() / 1000);
    data.setEndDate(plan.endDate.date().toString(Qt::ISODate));
    data.setEndTimeSecs(plan.endDate.time().msecsSinceStartOfDay() / 1000);
    data.setUnitId(plan.unitId);
    QtProtobuf::int32List rids;
    for (int rid : plan.routeIds) rids << rid;
    data.setRouteIds(rids);
    return data;
}

// ── Reference data sync ───────────────────────────────────────────────────────

void GrpcSyncBackend::syncReferenceData()
{
    auto unitsReply = m_client->GetUnits(calendar::Empty{});
    auto *rawUnits  = unitsReply.get();
    connect(rawUnits, &QGrpcCallReply::finished, this,
            [this, r = std::move(unitsReply)](const QGrpcStatus &status) {
        if (status.isOk()) {
            if (const auto resp = r->read<calendar::GetUnitsResponse>()) {
                QVariantList units;
                for (const auto &u : resp->units()) {
                    QVariantMap m;
                    m[QStringLiteral("id")]   = static_cast<int>(u.id_proto());
                    m[QStringLiteral("name")] = u.name();
                    units << m;
                }
                m_db->setUnits(units);
                qDebug() << "[GrpcSyncBackend] Loaded" << units.size() << "units from server";
            }
        } else {
            qWarning() << "[GrpcSyncBackend] GetUnits failed:" << status.message();
        }
    });

    auto routesReply = m_client->GetRoutes(calendar::Empty{});
    auto *rawRoutes  = routesReply.get();
    connect(rawRoutes, &QGrpcCallReply::finished, this,
            [this, r = std::move(routesReply)](const QGrpcStatus &status) {
        if (status.isOk()) {
            if (const auto resp = r->read<calendar::GetRoutesResponse>()) {
                QVariantList routes;
                for (const auto &rt : resp->routes()) {
                    QVariantMap m;
                    m[QStringLiteral("id")]   = static_cast<int>(rt.id_proto());
                    m[QStringLiteral("name")] = rt.name();
                    routes << m;
                }
                m_db->setRoutes(routes);
                qDebug() << "[GrpcSyncBackend] Loaded" << routes.size() << "routes from server";
            }
        } else {
            qWarning() << "[GrpcSyncBackend] GetRoutes failed:" << status.message();
        }
    });
}

// ── Plan subscription ─────────────────────────────────────────────────────────

void GrpcSyncBackend::startSubscription()
{
    calendar::SubscribePlansRequest req;
    // empty unit_ids = subscribe to all units

    m_planStream = m_client->SubscribePlans(req);

    connect(m_planStream.get(), &QGrpcServerStream::messageReceived, this, [this]() {
        if (const auto event = m_planStream->read<calendar::PlanEvent>())
            handlePlanEvent(*event);
    });

    connect(m_planStream.get(), &QGrpcServerStream::finished, this,
            [](const QGrpcStatus &status) {
        if (!status.isOk())
            qWarning() << "[GrpcSyncBackend] SubscribePlans stream ended:" << status.message();
        else
            qDebug() << "[GrpcSyncBackend] SubscribePlans stream closed cleanly";
    });

    qDebug() << "[GrpcSyncBackend] SubscribePlans stream opened";
}

void GrpcSyncBackend::handlePlanEvent(const calendar::PlanEvent &event)
{
    using PlanEventType = calendar::PlanEventTypeGadget::PlanEventType;
    const int id = static_cast<int>(event.id_proto());

    switch (event.type()) {
    case PlanEventType::PLAN_ADDED:
    case PlanEventType::PLAN_UPDATED: {
        const calendar::PlanData &d = event.data();
        QDate startDate = QDate::fromString(d.startDate(), Qt::ISODate);
        QDate endDate   = QDate::fromString(d.endDate(),   Qt::ISODate);
        QList<int> routeIds;
        for (auto rid : d.routeIds()) routeIds.append(static_cast<int>(rid));

        qDebug() << "[GrpcSyncBackend] Remote"
                 << (event.type() == PlanEventType::PLAN_ADDED ? "PLAN_ADDED" : "PLAN_UPDATED")
                 << "id=" << id;

        m_db->applyRemotePlan(id, d.name(), startDate, d.startTimeSecs(),
                              endDate, d.endTimeSecs(), static_cast<int>(d.unitId()),
                              routeIds);
        break;
    }
    case PlanEventType::PLAN_DELETED:
        qDebug() << "[GrpcSyncBackend] Remote PLAN_DELETED id=" << id;
        m_db->applyRemoteDelete(id);
        break;
    }
}

// ── Plan push mutations ───────────────────────────────────────────────────────

void GrpcSyncBackend::pushAddedPlan(int id)
{
    const Plan plan = m_db->planById(id);
    if (plan.id < 0) return;

    calendar::AddPlanRequest req;
    req.setData(planToProto(plan));

    auto reply   = m_client->AddPlan(req);
    auto *rawPtr = reply.get();
    connect(rawPtr, &QGrpcCallReply::finished, this,
            [id, r = std::move(reply)](const QGrpcStatus &status) {
        if (!status.isOk())
            qWarning() << "[GrpcSyncBackend] AddPlan" << id << "failed:" << status.message();
    });
}

void GrpcSyncBackend::pushUpdatedPlan(int id)
{
    const Plan plan = m_db->planById(id);
    if (plan.id < 0) return;

    calendar::UpdatePlanRequest req;
    req.setId_proto(id);
    req.setData(planToProto(plan));

    auto reply   = m_client->UpdatePlan(req);
    auto *rawPtr = reply.get();
    connect(rawPtr, &QGrpcCallReply::finished, this,
            [id, r = std::move(reply)](const QGrpcStatus &status) {
        if (!status.isOk())
            qWarning() << "[GrpcSyncBackend] UpdatePlan" << id << "failed:" << status.message();
    });
}

void GrpcSyncBackend::pushDeletedPlan(int id)
{
    calendar::DeletePlanRequest req;
    req.setId_proto(id);

    auto reply   = m_client->DeletePlan(req);
    auto *rawPtr = reply.get();
    connect(rawPtr, &QGrpcCallReply::finished, this,
            [id, r = std::move(reply)](const QGrpcStatus &status) {
        if (!status.isOk())
            qWarning() << "[GrpcSyncBackend] DeletePlan" << id << "failed:" << status.message();
    });
}
