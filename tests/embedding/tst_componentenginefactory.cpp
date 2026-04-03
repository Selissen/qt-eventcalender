// tst_componentenginefactory.cpp — unit tests for ComponentEngineFactory.
//
// Covers the configurable artifacts directory and the convenience
// createController(entrypoint) overload.  Flutter API calls go through the
// stubs so no real Flutter engine is needed.
#ifndef Q_OS_WASM

#include <QtTest>
#include <QCoreApplication>

#include "flutter_stub.h"

#include "../../QtFlutterEmbedding/ComponentEngineFactory.h"

class TstComponentEngineFactory : public QObject {
    Q_OBJECT

private slots:
    void init()
    {
        FlutterStub::reset();
        // Reset to empty so each test starts from a known default state.
        ComponentEngineFactory::setArtifactsDir(QString{});
    }

    // ── 1. Default dir is applicationDirPath() ────────────────────────────
    void artifactsDirDefaultsToAppDir()
    {
        QCOMPARE(ComponentEngineFactory::artifactsDir(),
                 QCoreApplication::applicationDirPath());
    }

    // ── 2. setArtifactsDir / artifactsDir round-trip ──────────────────────
    void artifactsDirRoundTrip()
    {
        ComponentEngineFactory::setArtifactsDir(QStringLiteral("/custom/path"));
        QCOMPARE(ComponentEngineFactory::artifactsDir(),
                 QStringLiteral("/custom/path"));
    }

    // ── 3. Resetting to empty restores the default ────────────────────────
    void clearArtifactsDirRestoresDefault()
    {
        ComponentEngineFactory::setArtifactsDir(QStringLiteral("/custom/path"));
        ComponentEngineFactory::setArtifactsDir(QString{});
        QCOMPARE(ComponentEngineFactory::artifactsDir(),
                 QCoreApplication::applicationDirPath());
    }

    // ── 4. Convenience overload with missing dir returns nullptr ──────────
    // The full createController() validates that flutter_assets/ and icudtl.dat
    // exist before touching the Flutter C API.  A non-existent dir must cause
    // a nullptr return without crashing.
    void convenienceOverloadMissingDirReturnsNull()
    {
        ComponentEngineFactory::setArtifactsDir(
            QStringLiteral("/nonexistent_qtfe_test_dir_xyz"));

        auto* ctrl = ComponentEngineFactory::createController(
            QStringLiteral("testEntrypoint"));

        QVERIFY(ctrl == nullptr);
        // No Flutter engine should have been created.
        QVERIFY(FlutterStub::takeSends().isEmpty());
    }

    // ── 5. Full overload with missing assets path returns nullptr ─────────
    void fullOverloadMissingAssetsReturnsNull()
    {
        auto* ctrl = ComponentEngineFactory::createController(
            QStringLiteral("/nonexistent/flutter_assets"),
            QStringLiteral("/nonexistent/icudtl.dat"),
            QString{},
            QStringLiteral("testEntrypoint"));

        QVERIFY(ctrl == nullptr);
    }

    // ── 6. Full overload with empty entrypoint returns nullptr ────────────
    void fullOverloadEmptyEntrypointReturnsNull()
    {
        auto* ctrl = ComponentEngineFactory::createController(
            QStringLiteral("/some/assets"),
            QStringLiteral("/some/icudtl.dat"),
            QString{},
            QStringLiteral("") /*entrypoint*/);

        QVERIFY(ctrl == nullptr);
    }
};

QTEST_MAIN(TstComponentEngineFactory)
#include "tst_componentenginefactory.moc"

#endif // Q_OS_WASM
