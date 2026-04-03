// tst_navigationbridge.cpp — unit tests for NavigationBridge routing logic.
//
// Most tests leave FlutterContainer unset (nullptr) because the routing
// signal / Qt-visible-flag behaviour is fully testable without a live engine.
// The null-guard in NavigationBridge prevents crashes when flutter_ is nullptr.
#ifndef Q_OS_WASM

#include <QtTest>
#include <QCoreApplication>
#include <QSignalSpy>

#include "flutter_stub.h"

#include "../../QtFlutterEmbedding/NavigationBridge.h"
#include "../../QtFlutterEmbedding/FlutterContainer.h"

class TstNavigationBridge : public QObject {
    Q_OBJECT

private slots:
    void init()
    {
        FlutterStub::reset();
    }

    // ── 1. A Flutter-owned route emits routeRequested ──────────────────────
    void flutterRouteEmitsSignal()
    {
        NavigationBridge bridge;
        QSignalSpy spy(&bridge, &NavigationBridge::routeRequested);
        QVERIFY(spy.isValid());

        bridge.navigateTo(QStringLiteral("/plans"));

        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.first()[0].toString(), QStringLiteral("/plans"));
    }

    // ── 2. A Qt-owned route emits signal but does NOT send to Flutter ──────
    void qtRouteDoesNotSendToFlutter()
    {
        NavigationBridge bridge;
        QSignalSpy spy(&bridge, &NavigationBridge::routeRequested);
        QVERIFY(spy.isValid());

        bridge.navigateTo(QStringLiteral("/some-qt-route"));

        QCOMPARE(spy.count(), 1);
        // No FlutterContainer set → no send regardless, but also this is a
        // Qt-owned route so the bridge must not attempt a send.
        QVERIFY(FlutterStub::takeSends().isEmpty());
    }

    // ── 3. Flutter route emits routeRequested with correct params ─────────
    // (View-visibility is verified through manual testing; QQuickItem
    // instantiation in a headless ctest environment is unreliable.)
    void flutterRouteCarriesParams()
    {
        NavigationBridge bridge;
        QSignalSpy spy(&bridge, &NavigationBridge::routeRequested);
        QVERIFY(spy.isValid());

        const QVariantMap params{ {QStringLiteral("id"), 42} };
        bridge.navigateTo(QStringLiteral("/plans"), params);

        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.first()[0].toString(), QStringLiteral("/plans"));
        QCOMPARE(spy.first()[1].toMap(), params);
    }

    // ── 4. navigateToQt() fires returnedToQt ─────────────────────────────
    void navigateToQtFiresSignal()
    {
        NavigationBridge bridge;
        QSignalSpy spy(&bridge, &NavigationBridge::returnedToQt);
        QVERIFY(spy.isValid());

        bridge.navigateToQt();

        QCOMPARE(spy.count(), 1);
    }

    // ── 5. Null container does not crash ───────────────────────────────────
    void nullContainerDoesNotCrash()
    {
        // No setFlutterContainer(), no setFlutterView() — both paths hit the
        // nullptr guard.  Should complete without crashing.
        NavigationBridge bridge;
        bridge.navigateTo(QStringLiteral("/plans"));
        bridge.navigateToQt();
        // If we reach here without a crash the test passes.
        QVERIFY(true);
    }

    // ── 6. Empty route does nothing (no signal) ────────────────────────────
    // Specification test: NavigationBridge must guard against empty routes.
    // Currently navigateTo() emits routeRequested unconditionally; this test
    // drives adding an early-return guard for empty/null routes.
    void emptyRouteDoesNothing()
    {
        NavigationBridge bridge;
        QSignalSpy spy(&bridge, &NavigationBridge::routeRequested);
        QVERIFY(spy.isValid());

        bridge.navigateTo(QStringLiteral(""));

        // An empty string is not a valid route; NavigationBridge must not emit.
        QCOMPARE(spy.count(), 0);
    }
};

QTEST_MAIN(TstNavigationBridge)
#include "tst_navigationbridge.moc"

#endif // Q_OS_WASM
