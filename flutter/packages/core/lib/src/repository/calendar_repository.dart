import 'package:grpc/grpc.dart';

import '../grpc_client.dart';
import '../proto/calendar.pb.dart';
import '../proto/calendar.pbgrpc.dart';

/// Single access point for all CalendarService RPCs.
///
/// Owns the gRPC [ClientChannel] lifecycle. Call [shutdown] when the app exits.
class CalendarRepository {
  CalendarRepository({
    String host = 'localhost',
    int port = 50051,
  }) : _channel = GrpcClientFactory.create(host: host, port: port) {
    _stub = CalendarServiceClient(_channel);
  }

  final ClientChannel _channel;
  late final CalendarServiceClient _stub;

  // ── Plans ─────────────────────────────────────────────────────────────────

  /// Opens a server-streaming subscription that delivers [PlanEvent]s.
  ///
  /// Emits PLAN_ADDED / PLAN_UPDATED / PLAN_DELETED events for every change.
  /// The stream stays open until the subscription is cancelled.
  Stream<PlanEvent> subscribePlans() =>
      _stub.subscribePlans(SubscribePlansRequest());

  /// Creates a new plan. Returns the server-assigned plan id.
  Future<int> addPlan(PlanData data) async {
    final response = await _stub.addPlan(AddPlanRequest(data: data));
    if (!response.success) throw Exception('AddPlan RPC returned success=false');
    return response.id;
  }

  /// Updates an existing plan by [id].
  Future<void> updatePlan(int id, PlanData data) async {
    final response = await _stub.updatePlan(UpdatePlanRequest(id: id, data: data));
    if (!response.success) {
      throw Exception('UpdatePlan RPC returned success=false');
    }
  }

  // ── Reference data ────────────────────────────────────────────────────────

  Future<List<Unit>> getUnits() async {
    final response = await _stub.getUnits(
      Empty(),
      options: CallOptions(timeout: const Duration(seconds: 5)),
    );
    return response.units;
  }

  Future<List<Route>> getRoutes() async {
    final response = await _stub.getRoutes(
      Empty(),
      options: CallOptions(timeout: const Duration(seconds: 5)),
    );
    return response.routes;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> shutdown() => _channel.shutdown();
}
