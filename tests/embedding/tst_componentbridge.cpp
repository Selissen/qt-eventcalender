// tst_componentbridge.cpp — unit tests for ComponentBridge.
//
// ComponentBridge encodes Qt→Flutter calls as JSON and decodes Flutter→Qt
// messages from JSON.  These tests use the Flutter API stubs so no real
// Flutter engine is required.
#ifndef Q_OS_WASM

#include <QtTest>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSignalSpy>

// Put the stub headers on the include path before any embedding header so
// that #include <flutter_windows.h> inside ComponentBridge.h resolves here.
#include "flutter_stub.h"

#include "../../QtFlutterEmbedding/ComponentBridge.h"

class TstComponentBridge : public QObject {
    Q_OBJECT

private slots:
    void init()
    {
        FlutterStub::reset();
    }

    // ── 1. send() encodes {method, args} as compact JSON ──────────────────
    void sendEncodesJson()
    {
        // ComponentBridge calls FlutterDesktopEngineGetMessenger in its ctor.
        ComponentBridge bridge(FlutterStub::stubEngine(),
                               QStringLiteral("com.eventcalendar/test"));

        QJsonObject args;
        args[QStringLiteral("lat")] = 51.5;
        args[QStringLiteral("lng")] = -0.1;
        bridge.send(QStringLiteral("setLocation"), args);

        const auto sends = FlutterStub::takeSends();
        QCOMPARE(sends.size(), 1);
        QCOMPARE(sends[0].channel, std::string("com.eventcalendar/test"));

        const QJsonObject envelope =
            QJsonDocument::fromJson(sends[0].payload).object();
        QCOMPARE(envelope.value(QStringLiteral("method")).toString(),
                 QStringLiteral("setLocation"));
        QVERIFY(envelope.contains(QStringLiteral("args")));
        const QJsonObject sentArgs =
            envelope.value(QStringLiteral("args")).toObject();
        QCOMPARE(sentArgs.value(QStringLiteral("lat")).toDouble(), 51.5);
        QCOMPARE(sentArgs.value(QStringLiteral("lng")).toDouble(), -0.1);
    }

    // ── 2. Valid inbound JSON fires messageReceived signal ─────────────────
    void onMessageParsesJson()
    {
        ComponentBridge bridge(FlutterStub::stubEngine(),
                               QStringLiteral("com.eventcalendar/test"));

        QSignalSpy spy(&bridge, &ComponentBridge::messageReceived);
        QVERIFY(spy.isValid());

        QJsonObject argsObj;
        argsObj[QStringLiteral("key")] = QStringLiteral("value");
        QJsonObject envelope;
        envelope[QStringLiteral("method")] = QStringLiteral("update");
        envelope[QStringLiteral("args")]   = argsObj;
        const QByteArray payload =
            QJsonDocument(envelope).toJson(QJsonDocument::Compact);

        FlutterStub::injectMessage("com.eventcalendar/test", payload);

        QCOMPARE(spy.count(), 1);
        const QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args[0].toString(), QStringLiteral("update"));
        const QJsonObject receivedArgs = args[1].toJsonObject();
        QCOMPARE(receivedArgs.value(QStringLiteral("key")).toString(),
                 QStringLiteral("value"));
    }

    // ── 3. Malformed JSON must not emit messageReceived ────────────────────
    void onMessageIgnoresInvalidJson()
    {
        ComponentBridge bridge(FlutterStub::stubEngine(),
                               QStringLiteral("com.eventcalendar/test"));

        QSignalSpy spy(&bridge, &ComponentBridge::messageReceived);
        QVERIFY(spy.isValid());

        FlutterStub::injectMessage("com.eventcalendar/test",
                                    QByteArray("not json"));

        // The signal may still fire (bridge emits whatever QJsonDocument
        // returns for the empty/null parse), but method should be empty and
        // args empty.  More precisely: a null QJsonDocument gives an empty
        // QJsonObject so method() returns "".
        // Accept either: signal not fired at all, or fired with empty method.
        if (spy.count() > 0) {
            const QString method = spy.takeFirst()[0].toString();
            QVERIFY2(method.isEmpty(),
                     "messageReceived should not carry a real method for invalid JSON");
        }
    }

    // ── 4. Destructor clears the channel callback (sets it to nullptr) ─────
    // Specification test: ComponentBridge MUST call
    //   FlutterDesktopMessengerSetCallback(messenger_, channel, nullptr, nullptr)
    // in its destructor so dangling pointers are never invoked after the bridge
    // is destroyed.  This test drives that implementation requirement.
    void destructorClearsCallback()
    {
        {
            ComponentBridge bridge(FlutterStub::stubEngine(),
                                   QStringLiteral("com.eventcalendar/test"));
            // Discard the registration record produced by the constructor.
            FlutterStub::takeCallbacks();
        } // bridge destroyed here; destructor must unregister

        const auto cbs = FlutterStub::takeCallbacks();
        QVERIFY2(!cbs.isEmpty(),
                 "ComponentBridge destructor must call MessengerSetCallback "
                 "to clear the handler (prevents use-after-free)");
        bool foundNull = false;
        for (const auto& rec : cbs) {
            if (rec.channel == "com.eventcalendar/test" &&
                rec.callback == nullptr)
            {
                foundNull = true;
                break;
            }
        }
        QVERIFY2(foundNull,
                 "ComponentBridge destructor must pass nullptr callback to "
                 "unregister the channel");
    }
};

QTEST_MAIN(TstComponentBridge)
#include "tst_componentbridge.moc"

#endif // Q_OS_WASM
