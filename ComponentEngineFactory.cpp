#ifndef Q_OS_WASM

#include "ComponentEngineFactory.h"
#include <QDebug>

FlutterDesktopViewControllerRef ComponentEngineFactory::createController(
    const QString& assetsPath,
    const QString& icuDataPath,
    const QString& aotLibraryPath,
    const QString& componentRoute,
    int initialWidth,
    int initialHeight)
{
    // Lifetime: toStdWString/toStdString temporaries must outlive FlutterDesktopEngineCreate.
    const std::wstring assets     = assetsPath.toStdWString();
    const std::wstring icu        = icuDataPath.toStdWString();
    const std::wstring aot        = aotLibraryPath.toStdWString();

    // Map component route → Dart entrypoint function name.
    // The Dart function must be annotated with @pragma('vm:entry-point').
    // Add an entry here for every new component added to ComponentEngineFactory.
    static const QMap<QString, QString> kEntrypoints = {
        { QStringLiteral("/map-component"), QStringLiteral("mapComponentMain") },
    };
    const QByteArray entrypointUtf8 =
        kEntrypoints.value(componentRoute, QStringLiteral("main")).toUtf8();

    FlutterDesktopEngineProperties props = {};
    props.assets_path      = assets.c_str();
    props.icu_data_path    = icu.c_str();
    props.aot_library_path = aot.empty() ? nullptr : aot.c_str();
    props.dart_entrypoint  = entrypointUtf8.constData();

    FlutterDesktopEngineRef engine = FlutterDesktopEngineCreate(&props);
    if (!engine) {
        qWarning("[ComponentEngineFactory] FlutterDesktopEngineCreate failed "
                 "for route: %s", qPrintable(componentRoute));
        return nullptr;
    }

    FlutterDesktopViewControllerRef controller =
        FlutterDesktopViewControllerCreate(initialWidth, initialHeight, engine);
    if (!controller) {
        qWarning("[ComponentEngineFactory] FlutterDesktopViewControllerCreate "
                 "failed for route: %s", qPrintable(componentRoute));
        FlutterDesktopEngineDestroy(engine);
        return nullptr;
    }

    return controller;
}

#endif // Q_OS_WASM
