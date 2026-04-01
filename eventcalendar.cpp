// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

#include "sqlplandatabase.h"
#include "plansyncmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QIcon::setThemeName("eventcalendar");

    QQmlApplicationEngine engine;
    // On desktop the engine may find the build-directory filesystem copy of
    // App/qmldir (prefer :/) before the embedded resource qmldir (prefer :/App/).
    // Prepending qrc:/ ensures the resource version wins.
    engine.addImportPath(QStringLiteral("qrc:/"));
    SqlPlanDatabase planDatabase;

    // PlanSyncManager mirrors local mutations to the backend.
    // Server URL is a placeholder — update when a real backend is available.
    // The manager fails gracefully when the server is unreachable.
#ifndef Q_OS_WASM
    const QUrl serverUrl(QStringLiteral("http://localhost:50051"));
#else
    const QUrl serverUrl(QStringLiteral("http://localhost:8080"));
#endif
    PlanSyncManager syncManager(&planDatabase, serverUrl);
    syncManager.start();

    engine.setInitialProperties({{ "planDatabase", QVariant::fromValue(&planDatabase) }});

    // The QML module is backed by eventcalendar_lib (static library), which
    // embeds all QML resources under the "/App/" prefix. This applies to both
    // desktop and WASM — the prefix-"/" copy that Qt generates for AoT is a
    // build artifact only and is not linked into the final binary.
    const QUrl url(QStringLiteral("qrc:/App/pages/eventcalendar.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
