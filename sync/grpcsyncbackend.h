#ifndef GRPCSYNCBACKEND_H
#define GRPCSYNCBACKEND_H

#include "syncbackend.h"

#include <memory>

class QAbstractGrpcChannel;
class QGrpcServerStream;
namespace calendar {
class PlanEvent;
namespace CalendarService { class Client; }
}

// gRPC sync backend — works with any QAbstractGrpcChannel subclass.
// The channel (QGrpcHttp2Channel on desktop, QGrpcWebChannel on WASM) is
// injected by the factory function in grpcchannel_http2.cpp / grpcchannel_web.cpp.
class GrpcSyncBackend : public ISyncBackend
{
    Q_OBJECT
public:
    explicit GrpcSyncBackend(SqlPlanDatabase *db,
                             std::shared_ptr<QAbstractGrpcChannel> channel,
                             QObject *parent = nullptr);
    ~GrpcSyncBackend() override = default;

    void syncReferenceData() override;
    void startSubscription()  override;

public slots:
    void pushAddedPlan(int id)   override;
    void pushUpdatedPlan(int id) override;
    void pushDeletedPlan(int id) override;

private:
    void handlePlanEvent(const calendar::PlanEvent &event);

    calendar::CalendarService::Client *m_client = nullptr;
    std::shared_ptr<QGrpcServerStream> m_planStream;
};

#endif // GRPCSYNCBACKEND_H
