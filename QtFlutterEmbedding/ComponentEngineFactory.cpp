#ifndef Q_OS_WASM

#include "ComponentEngineFactory.h"
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>

// Process-wide artifacts directory. Empty means "use applicationDirPath()".
static QString s_artifactsDir;

void ComponentEngineFactory::setArtifactsDir(const QString& path)
{
    s_artifactsDir = path;
}

QString ComponentEngineFactory::artifactsDir()
{
    return s_artifactsDir.isEmpty()
        ? QCoreApplication::applicationDirPath()
        : s_artifactsDir;
}

FlutterDesktopViewControllerRef ComponentEngineFactory::createController(
    const QString& entrypoint,
    int initialWidth,
    int initialHeight)
{
    const QString dir    = artifactsDir();
    const QString assets = dir + QStringLiteral("/flutter_assets");
    const QString icu    = dir + QStringLiteral("/icudtl.dat");
    const QString aot    = dir + QStringLiteral("/app.so");
    return createController(assets, icu,
                            QFile::exists(aot) ? aot : QString{},
                            entrypoint, initialWidth, initialHeight);
}

FlutterDesktopViewControllerRef ComponentEngineFactory::createController(
    const QString& assetsPath,
    const QString& icuDataPath,
    const QString& aotLibraryPath,
    const QString& entrypoint,
    int initialWidth,
    int initialHeight)
{
    if (assetsPath.isEmpty() || icuDataPath.isEmpty()) {
        qWarning("[ComponentEngineFactory] assetsPath and icuDataPath must not be empty.");
        return nullptr;
    }
    if (entrypoint.isEmpty()) {
        qWarning("[ComponentEngineFactory] entrypoint must not be empty.");
        return nullptr;
    }
    if (!QDir(assetsPath).exists()) {
        qWarning("[ComponentEngineFactory] flutter_assets not found at '%s'.",
                 qPrintable(assetsPath));
        return nullptr;
    }
    if (!QFile::exists(icuDataPath)) {
        qWarning("[ComponentEngineFactory] icudtl.dat not found at '%s'.",
                 qPrintable(icuDataPath));
        return nullptr;
    }

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
                 "for entrypoint '%s' (assets: '%s').",
                 qPrintable(entrypoint), qPrintable(assetsPath));
        return nullptr;
    }

    FlutterDesktopViewControllerRef controller =
        FlutterDesktopViewControllerCreate(initialWidth, initialHeight, engine);
    if (!controller) {
        qWarning("[ComponentEngineFactory] FlutterDesktopViewControllerCreate "
                 "failed for entrypoint '%s'.", qPrintable(entrypoint));
        FlutterDesktopEngineDestroy(engine);
        return nullptr;
    }

    return controller;
}

#endif // Q_OS_WASM
