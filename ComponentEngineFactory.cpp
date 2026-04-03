#ifndef Q_OS_WASM

#include "ComponentEngineFactory.h"
#include <QDebug>

FlutterDesktopViewControllerRef ComponentEngineFactory::createController(
    const QString& assetsPath,
    const QString& icuDataPath,
    const QString& aotLibraryPath,
    const QString& entrypoint,
    int initialWidth,
    int initialHeight)
{
    // Lifetime: wstring temporaries must outlive FlutterDesktopEngineCreate.
    const std::wstring assets = assetsPath.toStdWString();
    const std::wstring icu    = icuDataPath.toStdWString();
    const std::wstring aot    = aotLibraryPath.toStdWString();
    const QByteArray   ep     = entrypoint.toUtf8();

    FlutterDesktopEngineProperties props = {};
    props.assets_path      = assets.c_str();
    props.icu_data_path    = icu.c_str();
    props.aot_library_path = aot.empty() ? nullptr : aot.c_str();
    props.dart_entrypoint  = ep.constData();

    FlutterDesktopEngineRef engine = FlutterDesktopEngineCreate(&props);
    if (!engine) {
        qWarning("[ComponentEngineFactory] FlutterDesktopEngineCreate failed "
                 "for entrypoint: %s", qPrintable(entrypoint));
        return nullptr;
    }

    FlutterDesktopViewControllerRef controller =
        FlutterDesktopViewControllerCreate(initialWidth, initialHeight, engine);
    if (!controller) {
        qWarning("[ComponentEngineFactory] FlutterDesktopViewControllerCreate "
                 "failed for entrypoint: %s", qPrintable(entrypoint));
        FlutterDesktopEngineDestroy(engine);
        return nullptr;
    }

    return controller;
}

#endif // Q_OS_WASM
