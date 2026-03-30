// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

#include "sqlplandatabase.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QIcon::setThemeName("eventcalendar");

    QQmlApplicationEngine engine;
    SqlPlanDatabase planDatabase;
    engine.setInitialProperties({{ "planDatabase", QVariant::fromValue(&planDatabase) }});

    const QUrl url(QStringLiteral("qrc:/App/pages/eventcalendar.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
