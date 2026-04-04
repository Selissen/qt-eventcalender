import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../proto/calendar.pb.dart';
import '../proto/calendar.pbgrpc.dart' show CalendarServiceClient;
import '../providers.dart' show calendarServiceProvider;

/// Thin wrapper around the CalendarService gRPC stub for plan write operations.
///
/// Consume via [planMutationsProvider]; call [add] or [update] from form save
/// logic.  The live [plansProvider] stream picks up the resulting events
/// automatically — no manual invalidation is needed.
class PlanMutations {
  const PlanMutations(this._stub);
  final CalendarServiceClient _stub;

  /// Creates a new plan.  Returns the server-assigned plan id.
  Future<int> add(PlanData data) async {
    final response = await _stub.addPlan(AddPlanRequest(data: data));
    if (!response.success) throw Exception('AddPlan RPC returned success=false');
    return response.id;
  }

  /// Updates an existing plan by [id].
  Future<void> update(int id, PlanData data) async {
    final response =
        await _stub.updatePlan(UpdatePlanRequest(id: id, data: data));
    if (!response.success) {
      throw Exception('UpdatePlan RPC returned success=false');
    }
  }
}

final planMutationsProvider = Provider<PlanMutations>((ref) {
  return PlanMutations(ref.watch(calendarServiceProvider));
});
