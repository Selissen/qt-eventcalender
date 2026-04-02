// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifdef EC_FLUTTER_EMBED_ENABLED
#  include <QApplication>   // QWidget support required for FlutterContainer
#  include <windows.h>      // SetProcessDpiAwarenessContext
#  include "FlutterContainer.h"
#  include "FlutterFocusFilter.h"
#  include "NavigationBridge.h"
#else
#  include <QGuiApplication>
#endif

#include <QQmlApplicationEngine>
#include <QIcon>
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
    // DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 lets Windows manage it once.
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

#ifdef EC_FLUTTER_EMBED_ENABLED
    // ── Flutter embedding (Phase 0 validation) ────────────────────────────────
    // The FlutterContainer is shown as a separate top-level window for Phase 0
    // validation.  In Phase 1+ it will be integrated into the QML window hierarchy
    // via a platform-native container.
    //
    // flutter/app must be built first:
    //   cd flutter/app && flutter build windows --release
    //
    const QString exeDir = QCoreApplication::applicationDirPath();
    const QString assetsPath = exeDir + QStringLiteral("/flutter_assets");
    const QString icuPath    = exeDir + QStringLiteral("/icudtl.dat");
    const QString aotPath    = exeDir + QStringLiteral("/app.so"); // release AOT snapshot

    FlutterContainer* flutterContainer = nullptr;
    NavigationBridge* navBridge = new NavigationBridge(&app);

    if (QDir(assetsPath).exists() && QFile::exists(icuPath)) {
        flutterContainer = new FlutterContainer();
        flutterContainer->resize(1024, 768);
        // Pass aotPath only when the file exists (release); debug builds leave it empty.
        const QString resolvedAot = QFile::exists(aotPath) ? aotPath : QString{};
        if (flutterContainer->initialize(assetsPath, icuPath, resolvedAot)) {
            app.installNativeEventFilter(
                new FlutterFocusFilter(flutterContainer->flutterHwnd()));
            flutterContainer->show();
        } else {
            qWarning("[Flutter] FlutterContainer::initialize() failed — "
                     "check that flutter_assets/ and icudtl.dat are next to the executable.");
            delete flutterContainer;
            flutterContainer = nullptr;
        }
    } else {
        qWarning("[Flutter] flutter_assets/ or icudtl.dat not found next to executable. "
                 "Run:  cd flutter/app && flutter build windows --release  "
                 "then copy the build output alongside the Qt executable.");
    }

    Q_UNUSED(navBridge)
#endif // EC_FLUTTER_EMBED_ENABLED

    return app.exec();
}
