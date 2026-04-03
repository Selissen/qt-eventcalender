// tst_fluttercontainer.cpp — unit tests for FlutterContainer lifecycle.
//
// All Flutter API calls go through the stubs in flutter_stub.cpp so no real
// Flutter engine, DLL, or GPU is required.
#ifndef Q_OS_WASM

#include <QtTest>
#include <QCoreApplication>

#include <windows.h> // for GetDesktopWindow()

#include "flutter_stub.h"

#include "../../QtFlutterEmbedding/FlutterContainer.h"

class TstFlutterContainer : public QObject {
    Q_OBJECT

private slots:
    void init()
    {
        FlutterStub::reset();
    }

    // ── 1. initialize() returns false when engine creation fails ──────────
    void initializeFailsIfEngineCreateFails()
    {
        FlutterStub::failNextEngineCreate();

        FlutterContainer container;
        const bool ok = container.initialize(
            QStringLiteral("flutter_assets"),
            QStringLiteral("icudtl.dat"));

        QVERIFY2(!ok, "initialize() must return false when EngineCreate fails");
        QVERIFY2(container.messenger() == nullptr,
                 "messenger() must be nullptr after failed initialize()");
    }

    // ── 2. initialize() returns false when controller creation fails ───────
    void initializeFailsIfControllerCreateFails()
    {
        FlutterStub::failNextControllerCreate();

        FlutterContainer container;
        const bool ok = container.initialize(
            QStringLiteral("flutter_assets"),
            QStringLiteral("icudtl.dat"));

        QVERIFY2(!ok,
                 "initialize() must return false when ViewControllerCreate fails");
    }

    // ── 3. embedInto() before initialize() returns false ──────────────────
    void embedIntoBeforeInitializeReturnsFalse()
    {
        FlutterContainer container;
        // GetDesktopWindow() is always a valid HWND on Windows.
        const bool ok = container.embedInto(::GetDesktopWindow());
        QVERIFY2(!ok,
                 "embedInto() must return false before initialize() is called");
    }

    // ── 4. moveToRect() before initialize() does not crash ────────────────
    void moveToRectBeforeInitializeDoesNotCrash()
    {
        FlutterContainer container;
        container.moveToRect(0, 0, 800, 600); // guarded by flutterHwnd() == nullptr
        QVERIFY(true); // reaching here == no crash
    }

    // ── 5. show/hide before initialize() do not crash ─────────────────────
    void showHideBeforeInitializeDoesNotCrash()
    {
        FlutterContainer container;
        container.showEmbedded();
        container.hideEmbedded();
        QVERIFY(true);
    }

    // ── 6. messenger() returns nullptr before initialize() ────────────────
    void messengerNullBeforeInitialize()
    {
        FlutterContainer container;
        QVERIFY2(container.messenger() == nullptr,
                 "messenger() must return nullptr before initialize()");
    }

    // ── 7. A second initialize() on the same container returns false ───────
    // FlutterContainer holds a single engine/controller; calling initialize()
    // again while already initialised would leak resources.  The guard must
    // detect that engine_ is already set and return false.
    void doubleInitializeReturnsFalse()
    {
        FlutterContainer container;
        const bool first = container.initialize(
            QStringLiteral("flutter_assets"),
            QStringLiteral("icudtl.dat"));
        QVERIFY2(first, "First initialize() must succeed with stub engine");

        const bool second = container.initialize(
            QStringLiteral("flutter_assets"),
            QStringLiteral("icudtl.dat"));
        QVERIFY2(!second,
                 "Second initialize() on the same container must return false "
                 "to prevent resource leaks");
    }
};

QTEST_MAIN(TstFlutterContainer)
#include "tst_fluttercontainer.moc"

#endif // Q_OS_WASM
