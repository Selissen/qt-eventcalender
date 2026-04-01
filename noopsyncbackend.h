#ifndef NOOPSYNCBACKEND_H
#define NOOPSYNCBACKEND_H

#include "syncbackend.h"

class NoopSyncBackend : public ISyncBackend
{
    Q_OBJECT
public:
    explicit NoopSyncBackend(SqlPlanDatabase *db, const QUrl &serverUrl, QObject *parent = nullptr);
    ~NoopSyncBackend() override = default;

    void syncReferenceData() override {}

public slots:
    void pushAddedPlan(int)   override {}
    void pushUpdatedPlan(int) override {}
    void pushDeletedPlan(int) override {}
};

#endif // NOOPSYNCBACKEND_H
