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
    if (messenger_)
        FlutterDesktopMessengerSetCallback(
            messenger_, channel_.c_str(), onMessage, this);
    else
        qWarning("[ComponentBridge] engine returned null messenger for '%s'",
                 channel_.c_str());
}

ComponentBridge::~ComponentBridge()
{
    // Unregister before the engine/messenger is torn down so no in-flight
    // callbacks arrive after this object is freed.
    if (messenger_)
        FlutterDesktopMessengerSetCallback(
            messenger_, channel_.c_str(), nullptr, nullptr);
}

void ComponentBridge::send(const QString& method, const QJsonObject& args)
{
    if (!messenger_) {
        emit sendFailed(QStringLiteral("Messenger not available on channel '%1'")
                            .arg(QString::fromStdString(channel_)));
        return;
    }

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
    if (!user_data || !message || message->message_size == 0) return;

    auto* self = static_cast<ComponentBridge*>(user_data);
    const QByteArray raw(reinterpret_cast<const char*>(message->message),
                         static_cast<int>(message->message_size));

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(raw, &err);
    if (doc.isNull()) {
        qWarning("[ComponentBridge] invalid JSON on channel '%s': %s",
                 message->channel ? message->channel : "?",
                 qPrintable(err.errorString()));
        return;
    }

    const QJsonObject obj = doc.object();
    emit self->messageReceived(
        obj.value(QStringLiteral("method")).toString(),
        obj.value(QStringLiteral("args")).toObject());
}

#endif // Q_OS_WASM
