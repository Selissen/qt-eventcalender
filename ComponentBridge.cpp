#ifndef Q_OS_WASM

#include "ComponentBridge.h"
#include <QJsonDocument>
#include <QDebug>

ComponentBridge::ComponentBridge(FlutterDesktopEngineRef engine,
                                 const QString& channel,
                                 QObject* parent)
    : QObject(parent),
      messenger_(FlutterDesktopEngineGetMessenger(engine)),
      channel_(channel.toStdString())
{
    FlutterDesktopMessengerSetCallback(
        messenger_, channel_.c_str(), onMessage, this);
}

void ComponentBridge::send(const QString& method, const QJsonObject& args)
{
    QJsonObject envelope;
    envelope[QStringLiteral("method")] = method;
    envelope[QStringLiteral("args")]   = args;
    const QByteArray data =
        QJsonDocument(envelope).toJson(QJsonDocument::Compact);

    FlutterDesktopMessengerSend(
        messenger_,
        channel_.c_str(),
        reinterpret_cast<const uint8_t*>(data.constData()),
        static_cast<size_t>(data.size()));
}

void ComponentBridge::onMessage(FlutterDesktopMessengerRef,
                                const FlutterDesktopMessage* message,
                                void* user_data)
{
    auto* self = static_cast<ComponentBridge*>(user_data);
    const QByteArray raw(reinterpret_cast<const char*>(message->message),
                         static_cast<int>(message->message_size));
    const QJsonObject obj = QJsonDocument::fromJson(raw).object();
    emit self->messageReceived(
        obj.value(QStringLiteral("method")).toString(),
        obj.value(QStringLiteral("args")).toObject());
}

#endif // Q_OS_WASM
