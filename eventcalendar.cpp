// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifdef EC_FLUTTER_EMBED_ENABLED
#  include <QApplication>
#  include <QQuickWindow>
#  include <QQmlEngine>
#  include <windows.h>
#  include "FlutterContainer.h"
#  include "FlutterFocusFilter.h"
#  include "FlutterView.h"
#  include "FlutterComponentView.h"
#  include "NavigationBridge.h"
#else
#  include <QGuiApplication>
#endif

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QFile>
#include <QDir>
#include <QCoreApplication>

#include "sqlplandatabase.h"
#include "plansyncmanager.h"

// Suppress benign "Mutable view on type already registered" warnings emitted by
// Qt Protobuf's generated type registration code.  These fire from
// Q_CONSTRUCTOR_FUNCTION (C++ global constructors) in the generated protobuf TU,
// so a handler installed in main() or via a peer global constructor arrives too
// late.  __attribute__((constructor(200))) is guaranteed by GCC/Clang (MinGW and
// Emscripten) to run before default-priority C++ static initializers, so our
// filter is active before any protobuf registration warning can be emitted.
static QtMessageHandler g_previousHandler = nullptr;
static void filteredMessageHandler(QtMsgType type,
                                   const QMessageLogContext &ctx,
                                   const QString &msg)
{
    if (type == QtWarningMsg
            && msg.contains(QLatin1String("Mutable view on type already registered")))
        return;
    if (g_previousHandler)
        g_previousHandler(type, ctx, msg);
    else
        qt_message_output(type, ctx, msg);
}
__attribute__((constructor(200))) static void installFilteredMessageHandler()
{
    g_previousHandler = qInstallMessageHandler(filteredMessageHandler);
}

int main(int argc, char *argv[])
{
#ifdef EC_FLUTTER_EMBED_ENABLED
    // Prevent double-scaling: Qt and Flutter each apply DPI scaling independently.
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    QApplication::setAttribute(Qt::AA_DisableHighDpiScaling);
    QApplication app(argc, argv);
#else
    QGuiApplication app(argc, argv);
#endif

    QIcon::setThemeName("eventcalendar");

    QQmlApplicationEngine engine;
    // On desktop the engine may find the build-directory filesystem copy of
    // App/qmldir (prefer :/) before the embedded resource qmldir (prefer :/App/).
    // Prepending qrc:/ ensures the resource version wins.
    engine.addImportPath(QStringLiteral("qrc:/"));
    SqlPlanDatabase planDatabase;

#ifndef Q_OS_WASM
    const QUrl serverUrl(QStringLiteral("http://localhost:50051"));
#else
    const QUrl serverUrl(QStringLiteral("http://localhost:8080"));
#endif
    PlanSyncManager syncManager(&planDatabase, serverUrl);
    syncManager.start();

    engine.setInitialProperties({{ "planDatabase", QVariant::fromValue(&planDatabase) }});

#ifdef EC_FLUTTER_EMBED_ENABLED
    // ── Phase 1: Flutter embedded inside the QML window ──────────────────────
    const QString exeDir    = QCoreApplication::applicationDirPath();
    const QString assetsPath = exeDir + QStringLiteral("/flutter_assets");
    const QString icuPath    = exeDir + QStringLiteral("/icudtl.dat");
    const QString aotPath    = exeDir + QStringLiteral("/app.so");

    FlutterContainer* flutter   = nullptr;
    NavigationBridge* navBridge = new NavigationBridge(&app);

    if (QDir(assetsPath).exists() && QFile::exists(icuPath)) {
        flutter = new FlutterContainer(&app);
        const QString resolvedAot = QFile::exists(aotPath) ? aotPath : QString{};

        if (!flutter->initialize(assetsPath, icuPath, resolvedAot)) {
            qWarning("[Flutter] initialize() failed — running Qt-only.");
            delete flutter;
            flutter = nullptr;
        } else {
            navBridge->setFlutterContainer(flutter);
            navBridge->setFlutterRoutes({ QStringLiteral("/plans"),
                                          QStringLiteral("/widget-catalog") });
            app.installNativeEventFilter(new FlutterFocusFilter(flutter));
        }
    } else {
        qWarning("[Flutter] flutter_assets/ or icudtl.dat missing next to executable. "
                 "Run: cd flutter/app && flutter build windows --release");
    }

    // Expose navBridge to QML so the toolbar button can call navigateTo().
    // Set before engine.load() so it is available from the first frame.
    engine.rootContext()->setContextProperty(QStringLiteral("navBridge"), navBridge);

    // Register Flutter QML items so they can be used with normal anchors/layouts.
    qmlRegisterType<FlutterView>("App", 1, 0, "FlutterView");
    qmlRegisterType<FlutterComponentView>("App", 1, 0, "FlutterComponentView");
#endif // EC_FLUTTER_EMBED_ENABLED

    const QUrl url(QStringLiteral("qrc:/App/qml/pages/eventcalendar.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [&](QObject* obj, const QUrl& objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
            return;
        }

#ifdef EC_FLUTTER_EMBED_ENABLED
        if (!flutter || !obj) return;

        // The QML root is an ApplicationWindow (subclass of QQuickWindow).
        auto* qmlWindow = qobject_cast<QQuickWindow*>(obj);
        if (!qmlWindow) return;

        const HWND qmlHwnd = reinterpret_cast<HWND>(qmlWindow->winId());

        // Embed the Flutter view as a Win32 child of the QML window.
        // Position/size is managed by FlutterView via moveToRect(); no initial
        // size needed here — FlutterView's geometryChange() handles it.
        if (!flutter->embedInto(qmlHwnd)) {
            qWarning("[Flutter] embedInto() failed — Flutter will not be visible.");
            return;
        }

        // Register the Qt←Flutter back channel so Flutter can return to Qt.
        navBridge->listenForBackNavigation(flutter->messenger());
        qDebug() << "[Flutter] Embedded — toolbar button is active.";
#endif // EC_FLUTTER_EMBED_ENABLED
    }, Qt::QueuedConnection);

    engine.load(url);


    return app.exec();
}
