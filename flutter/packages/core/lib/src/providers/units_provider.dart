import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../proto/calendar.pb.dart';
import '../providers.dart' show calendarServiceProvider;

/// Fetches the full unit list once via GetUnits RPC and caches it.
/// keepAlive is set so the list survives screen navigations; units change rarely.
final unitsProvider = FutureProvider<List<Unit>>((ref) async {
  ref.keepAlive();
  final stub = ref.watch(calendarServiceProvider);
  final response = await stub.getUnits(Empty());
  return response.units;
});
