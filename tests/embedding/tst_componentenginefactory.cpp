// tst_componentenginefactory.cpp — unit tests for ComponentEngineFactory.
//
// Covers the configurable artifacts directory and the convenience
// createController(entrypoint) overload.  Flutter API calls go through the
// stubs so no real Flutter engine is needed.
#ifndef Q_OS_WASM

#include <QtTest>
#include <QCoreApplication>
#include <QDir>
#include <QFile>

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

    // ── 7. instanceId is forwarded as --instanceId= argv ─────────────────
    // When createController is called with a non-empty instanceId the engine
    // must be created with dart_entrypoint_argv containing "--instanceId=<id>".
    void instanceIdPassedAsArgv()
    {
        // createController validates that flutter_assets/ and icudtl.dat exist,
        // so use the convenience overload which skips the path checks when the
        // artifacts dir doesn't exist.  We only want to observe what was passed
        // to FlutterDesktopEngineCreate.
        //
        // Set a real-looking but non-existent dir so the factory returns nullptr
        // after the engine create (path validation happens before create).
        // Actually — the full overload checks paths first. Use a non-existent
        // path to exercise the early-return path, which means EngineCreate is
        // never called. Instead, set up a real-looking dir via the stub.
        //
        // Simplest approach: the convenience overload already calls the full
        // overload after building paths from artifactsDir(). Since the paths
        // won't exist the factory returns nullptr before EngineCreate. So we
        // test the full overload directly with existing paths.
        //
        // We can't easily create real paths in a unit test. Instead we rely on
        // the stub: FlutterDesktopEngineCreate always succeeds unless explicitly
        // failed, regardless of the path strings passed. The path existence check
        // in createController happens BEFORE EngineCreate. So we need valid
        // paths for the check to pass.
        //
        // Create temporary flutter_assets dir and icudtl.dat file in the test's
        // temp directory.
        const QString tmp = QDir::tempPath() + QStringLiteral("/qtfe_test_factory");
        QDir().mkpath(tmp + QStringLiteral("/flutter_assets"));
        { QFile icu(tmp + QStringLiteral("/icudtl.dat")); static_cast<void>(icu.open(QIODevice::WriteOnly)); }

        auto* ctrl = ComponentEngineFactory::createController(
            tmp + QStringLiteral("/flutter_assets"),
            tmp + QStringLiteral("/icudtl.dat"),
            QString{} /*aot*/,
            QStringLiteral("mapComponentMain"),
            QStringLiteral("planning") /*instanceId*/);

        QVERIFY(ctrl != nullptr);

        const auto rec = FlutterStub::takeLastEngineCreate();
        QCOMPARE(rec.entrypoint, std::string("mapComponentMain"));
        QCOMPARE(static_cast<int>(rec.argv.size()), 1);
        QCOMPARE(rec.argv[0], std::string("--instanceId=planning"));

        // Cleanup
        QDir(tmp).removeRecursively();
    }

    // ── 8. Empty instanceId produces no argv ─────────────────────────────
    void emptyInstanceIdProducesNoArgv()
    {
        const QString tmp = QDir::tempPath() + QStringLiteral("/qtfe_test_factory2");
        QDir().mkpath(tmp + QStringLiteral("/flutter_assets"));
        { QFile icu(tmp + QStringLiteral("/icudtl.dat")); static_cast<void>(icu.open(QIODevice::WriteOnly)); }

        auto* ctrl = ComponentEngineFactory::createController(
            tmp + QStringLiteral("/flutter_assets"),
            tmp + QStringLiteral("/icudtl.dat"),
            QString{},
            QStringLiteral("mapComponentMain"),
            QString{} /*instanceId — empty*/);

        QVERIFY(ctrl != nullptr);

        const auto rec = FlutterStub::takeLastEngineCreate();
        QVERIFY(rec.argv.empty());

        QDir(tmp).removeRecursively();
    }
};

QTEST_MAIN(TstComponentEngineFactory)
#include "tst_componentenginefactory.moc"

#endif // Q_OS_WASM
