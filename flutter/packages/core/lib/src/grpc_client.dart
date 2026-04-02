import 'package:grpc/grpc.dart';

class GrpcClientFactory {
  static ClientChannel create({
    required String host,
    required int port,
    bool useTls = false,
  }) {
    return ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: useTls
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
      ),
    );
  }
}
