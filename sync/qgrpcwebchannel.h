#ifndef QGRPCWEBCHANNEL_H
#define QGRPCWEBCHANNEL_H

#include <QAbstractGrpcChannel>
#include <QUrl>

#include <memory>

class QGrpcChannelOptions;
class QGrpcWebChannelPrivate;

// gRPC-Web channel for Qt gRPC — allows the same generated CalendarService::Client
// to communicate with a gRPC-Web proxy (e.g. Envoy) from a browser (WASM) context.
//
// Protocol: POST /{service}/{method}, Content-Type: application/grpc-web+proto
// Each request/response body uses 5-byte gRPC-Web length-prefix framing.
// Trailers are embedded as a 0x80-flagged frame at the end of the response body
// instead of HTTP trailers, which are blocked by the browser's fetch API.
//
// Supports:
//   - Unary calls  (call)
//   - Server streaming  (serverStream) — reads frames incrementally via readyRead
// Not supported (gRPC-Web / fetch API limitation):
//   - Client streaming, bidirectional streaming — emit Unimplemented status
class QGrpcWebChannel final : public QAbstractGrpcChannel
{
public:
    explicit QGrpcWebChannel(const QUrl &url);
    explicit QGrpcWebChannel(const QUrl &url, const QGrpcChannelOptions &options);
    ~QGrpcWebChannel() override;

    [[nodiscard]] QUrl hostUri() const;
    [[nodiscard]] std::shared_ptr<QAbstractProtobufSerializer> serializer() const override;

private:
    void call(QGrpcOperationContext *ctx, QByteArray &&messageData) override;
    void serverStream(QGrpcOperationContext *ctx, QByteArray &&messageData) override;
    void clientStream(QGrpcOperationContext *ctx, QByteArray &&messageData) override;
    void bidiStream(QGrpcOperationContext *ctx, QByteArray &&messageData) override;

    Q_DISABLE_COPY_MOVE(QGrpcWebChannel)
    std::unique_ptr<QGrpcWebChannelPrivate> d;
};

#endif // QGRPCWEBCHANNEL_H
