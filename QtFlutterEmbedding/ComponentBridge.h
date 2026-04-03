#pragma once
#ifndef Q_OS_WASM

#include <QObject>
#include <QJsonObject>
#include <flutter_windows.h>
#include <flutter_messenger.h>

/// Bidirectional JSON-over-MethodChannel bridge between a Qt screen and
/// an embedded Flutter component.
///
/// Channel naming convention: "com.eventcalendar/<component-name>"
///
/// Qt → Flutter:  bridge->send("setLocation", {{"lat", 51.5}, {"lng", -0.1}});
/// Flutter → Qt:  connect(bridge, &ComponentBridge::messageReceived, ...)
///
/// One ComponentBridge per component per engine. Create after the engine is
/// running (i.e., after FlutterContainer::initialize() or
/// ComponentEngineFactory::createController() returns).
class ComponentBridge : public QObject {
    Q_OBJECT
public:
    explicit ComponentBridge(FlutterDesktopEngineRef engine,
                             const QString& channel,
                             QObject* parent = nullptr);
    /// Unregisters the channel callback so no messages arrive after destruction.
    ~ComponentBridge() override;

    /// Send a method call to the Flutter component.
    /// Encoded as JSON: { "method": method, "args": args }
    void send(const QString& method, const QJsonObject& args = {});

signals:
    /// Emitted when the Flutter component sends a message back.
    void messageReceived(const QString& method, const QJsonObject& args);

private:
    static void onMessage(FlutterDesktopMessengerRef messenger,
                          const FlutterDesktopMessage* message,
                          void* user_data);

    FlutterDesktopMessengerRef messenger_;
    std::string                channel_;
};

#endif // Q_OS_WASM
