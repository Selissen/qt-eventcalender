import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'grpc_client.dart';

import 'proto/calendar.pbgrpc.dart';

const String _kGrpcHost = 'localhost';
const int _kGrpcPort = 50051;

final grpcChannelProvider = Provider<ClientChannel>((ref) {
  final channel = GrpcClientFactory.create(
    host: _kGrpcHost,
    port: _kGrpcPort,
  );
  ref.onDispose(channel.shutdown);
  return channel;
});

final calendarServiceProvider = Provider<CalendarServiceClient>((ref) {
  return CalendarServiceClient(ref.watch(grpcChannelProvider));
});
