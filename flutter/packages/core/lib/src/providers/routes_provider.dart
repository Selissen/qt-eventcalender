import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart' show CallOptions;
import '../proto/calendar.pb.dart';
import '../providers.dart' show calendarServiceProvider;

/// Fetches the full route list once via GetRoutes RPC and caches it.
/// keepAlive is set so the list survives screen navigations; routes change rarely.
final routesProvider = FutureProvider<List<Route>>((ref) async {
  ref.keepAlive();
  final stub = ref.watch(calendarServiceProvider);
  final response = await stub.getRoutes(
    Empty(),
    options: CallOptions(timeout: const Duration(seconds: 5)),
  );
  return response.routes;
});
