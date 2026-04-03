#include "qgrpcwebchannel.h"

#include <QAbstractProtobufSerializer>
#include <QGrpcChannelOptions>
#include <QGrpcOperationContext>
#include <QGrpcSerializationFormat>
#include <QGrpcStatus>

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <QtEndian>
#include <QDebug>

// ── Private worker (QObject for signal/slot use) ──────────────────────────────

class QGrpcWebChannelPrivate final : public QObject
{
    Q_OBJECT
public:
    explicit QGrpcWebChannelPrivate(const QUrl &url, QObject *parent = nullptr)
        : QObject(parent), m_url(url) {}

    void doCall(QGrpcOperationContext *ctx, const QByteArray &msgData,
                const QMultiHash<QByteArray, QByteArray> &channelMeta);

    void doServerStream(QGrpcOperationContext *ctx, const QByteArray &msgData,
                        const QMultiHash<QByteArray, QByteArray> &channelMeta);

    QUrl m_url;
    QNetworkAccessManager m_nam{this};
};

// ── gRPC-Web framing helpers ──────────────────────────────────────────────────

// Wraps a serialized protobuf message in a gRPC-Web data frame:
// [ 0x00 (uncompressed data) ][ 4-byte big-endian length ][ payload ]
static QByteArray encodeFrame(const QByteArray &payload)
{
    QByteArray frame;
    frame.reserve(5 + payload.size());
    frame += char(0x00);
    const quint32 len = qToBigEndian<quint32>(static_cast<quint32>(payload.size()));
    frame.append(reinterpret_cast<const char *>(&len), 4);
    frame += payload;
    return frame;
}

// Tries to read one complete frame from buf.
// Returns bytes consumed (0 = incomplete, need more data).
static int tryReadFrame(const QByteArray &buf, quint8 *flagOut, QByteArray *payloadOut)
{
    if (buf.size() < 5)
        return 0;
    *flagOut = static_cast<quint8>(buf.at(0));
    quint32 len = 0;
    memcpy(&len, buf.constData() + 1, 4);
    len = qFromBigEndian(len);
    if (buf.size() < 5 + static_cast<int>(len))
        return 0;
    *payloadOut = buf.mid(5, static_cast<int>(len));
    return 5 + static_cast<int>(len);
}

// Parses a gRPC-Web trailer frame payload (ASCII text, e.g.
// "grpc-status:0\r\ngrpc-message:OK\r\n") into a QGrpcStatus.
static QGrpcStatus parseTrailers(const QByteArray &payload)
{
    int code = static_cast<int>(QtGrpc::StatusCode::Unknown);
    QString message;
    for (const QByteArray &line : payload.split('\n')) {
        const QByteArray t = line.trimmed();
        if (t.startsWith("grpc-status:"))
            code = t.mid(12).trimmed().toInt();
        else if (t.startsWith("grpc-message:"))
            message = QString::fromUtf8(
                QByteArray::fromPercentEncoding(t.mid(13).trimmed()));
    }
    return QGrpcStatus{static_cast<QtGrpc::StatusCode>(code), message};
}

// Consumes all complete frames from buf, emitting signals on ctx.
// Updates *status whenever a trailer frame is found.
static void drainFrames(QByteArray &buf, QGrpcOperationContext *ctx, QGrpcStatus *status)
{
    while (!buf.isEmpty()) {
        quint8 flag = 0;
        QByteArray payload;
        const int consumed = tryReadFrame(buf, &flag, &payload);
        if (consumed == 0)
            break;
        buf.remove(0, consumed);
        if (flag == 0x00) {
            emit ctx->messageReceived(payload);
        } else if (flag == 0x80) {
            *status = parseTrailers(payload);
        }
        // Compressed frames (0x01, 0x81) are not supported; silently skip.
    }
}

// ── Request builder ───────────────────────────────────────────────────────────

static QNetworkRequest buildRequest(
    const QUrl &baseUrl,
    QGrpcOperationContext *ctx,
    const QMultiHash<QByteArray, QByteArray> &channelMeta)
{
    // URL: {baseUrl}/{service}/{method}
    QUrl url = baseUrl;
    QString path = url.path();
    if (path.endsWith(u'/'))
        path.chop(1);
    path += u'/' + QString::fromLatin1(ctx->service())
          + u'/' + QString::fromLatin1(ctx->method());
    url.setPath(path);

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader,
                  QByteArrayLiteral("application/grpc-web+proto"));
    req.setRawHeader("X-Grpc-Web", "1");
    req.setRawHeader("Accept", "application/grpc-web+proto");

    for (auto it = channelMeta.cbegin(); it != channelMeta.cend(); ++it)
        req.setRawHeader(it.key(), it.value());

    return req;
}

// ── Unary call ────────────────────────────────────────────────────────────────

void QGrpcWebChannelPrivate::doCall(
    QGrpcOperationContext *ctx,
    const QByteArray &msgData,
    const QMultiHash<QByteArray, QByteArray> &channelMeta)
{
    auto *reply = m_nam.post(buildRequest(m_url, ctx, channelMeta), encodeFrame(msgData));

    QObject::connect(ctx, &QGrpcOperationContext::cancelRequested, reply, [reply]() {
        reply->abort();
    });
    // Abort the in-flight request if the operation context is destroyed externally.
    QObject::connect(ctx, &QObject::destroyed, reply, [reply]() {
        reply->abort();
    });

    QObject::connect(reply, &QNetworkReply::finished, ctx,
                     [reply, ctx]() {
        if (reply->error() != QNetworkReply::NoError
            && reply->error() != QNetworkReply::OperationCanceledError) {
            emit ctx->finished(
                QGrpcStatus{QtGrpc::StatusCode::Unavailable, reply->errorString()});
            reply->deleteLater();
            return;
        }

        QByteArray buf = reply->readAll();
        QGrpcStatus status{QtGrpc::StatusCode::Unknown, QString{}};
        drainFrames(buf, ctx, &status);

        emit ctx->finished(status);
        reply->deleteLater();
    });
}

// ── Server-streaming call ─────────────────────────────────────────────────────

void QGrpcWebChannelPrivate::doServerStream(
    QGrpcOperationContext *ctx,
    const QByteArray &msgData,
    const QMultiHash<QByteArray, QByteArray> &channelMeta)
{
    auto *reply = m_nam.post(buildRequest(m_url, ctx, channelMeta), encodeFrame(msgData));

    QObject::connect(ctx, &QGrpcOperationContext::cancelRequested, reply, [reply]() {
        reply->abort();
    });
    QObject::connect(ctx, &QObject::destroyed, reply, [reply]() {
        reply->abort();
    });

    // Shared state — automatically freed when both lambdas release their shared_ptr.
    auto buf          = std::make_shared<QByteArray>();
    auto finalStatus  = std::make_shared<QGrpcStatus>(QtGrpc::StatusCode::Unknown, QString{});

    QObject::connect(reply, &QNetworkReply::readyRead, ctx,
                     [reply, ctx, buf, finalStatus]() {
        buf->append(reply->readAll());
        drainFrames(*buf, ctx, finalStatus.get());
    });

    QObject::connect(reply, &QNetworkReply::finished, ctx,
                     [reply, ctx, buf, finalStatus]() {
        // Drain any data that arrived between last readyRead and finished.
        buf->append(reply->readAll());
        drainFrames(*buf, ctx, finalStatus.get());

        QGrpcStatus result = *finalStatus;
        if (reply->error() != QNetworkReply::NoError
            && reply->error() != QNetworkReply::OperationCanceledError) {
            result = QGrpcStatus{QtGrpc::StatusCode::Unavailable, reply->errorString()};
        }

        emit ctx->finished(result);
        reply->deleteLater();
    });
}

// ── QGrpcWebChannel ───────────────────────────────────────────────────────────

QGrpcWebChannel::QGrpcWebChannel(const QUrl &url)
    : QGrpcWebChannel(url, QGrpcChannelOptions{})
{}

QGrpcWebChannel::QGrpcWebChannel(const QUrl &url, const QGrpcChannelOptions &options)
    : QAbstractGrpcChannel(options)
    , d(std::make_unique<QGrpcWebChannelPrivate>(url))
{}

QGrpcWebChannel::~QGrpcWebChannel() = default;

QUrl QGrpcWebChannel::hostUri() const
{
    return d->m_url;
}

std::shared_ptr<QAbstractProtobufSerializer> QGrpcWebChannel::serializer() const
{
    return channelOptions().serializationFormat().serializer();
}

void QGrpcWebChannel::call(QGrpcOperationContext *ctx, QByteArray &&messageData)
{
    d->doCall(ctx, messageData, channelOptions().metadata(QtGrpc::MultiValue));
}

void QGrpcWebChannel::serverStream(QGrpcOperationContext *ctx, QByteArray &&messageData)
{
    d->doServerStream(ctx, messageData, channelOptions().metadata(QtGrpc::MultiValue));
}

void QGrpcWebChannel::clientStream(QGrpcOperationContext *ctx, QByteArray &&)
{
    // Client streaming requires a streaming request body, which the browser
    // fetch API does not support. Emit Unimplemented immediately.
    qWarning() << "[QGrpcWebChannel] clientStream not supported over gRPC-Web ("
               << ctx->service() << "/" << ctx->method() << ")";
    emit ctx->finished(
        QGrpcStatus{QtGrpc::StatusCode::Unimplemented,
                    QStringLiteral("Client streaming is not supported over gRPC-Web")});
}

void QGrpcWebChannel::bidiStream(QGrpcOperationContext *ctx, QByteArray &&)
{
    qWarning() << "[QGrpcWebChannel] bidiStream not supported over gRPC-Web ("
               << ctx->service() << "/" << ctx->method() << ")";
    emit ctx->finished(
        QGrpcStatus{QtGrpc::StatusCode::Unimplemented,
                    QStringLiteral("Bidirectional streaming is not supported over gRPC-Web")});
}

// MOC output for QGrpcWebChannelPrivate (defined in this .cpp, not a header).
#include "qgrpcwebchannel.moc"
