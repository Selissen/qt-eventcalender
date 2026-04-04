import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../proto/calendar.pb.dart';
import '../proto/calendar.pbgrpc.dart';
import '../providers.dart' show calendarServiceProvider;

// ── Plan model ────────────────────────────────────────────────────────────────

/// Dart-side representation of a Plan, derived from the proto PlanData message.
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.startTimeSecs,
    required this.endTimeSecs,
    required this.unitId,
    required this.routeIds,
  });

  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final int startTimeSecs;
  final int endTimeSecs;
  final int unitId;
  final List<int> routeIds;

  static Plan fromEvent(PlanEvent event) => Plan(
        id: event.id,
        name: event.data.name,
        startDate: event.data.startDate,
        endDate: event.data.endDate,
        startTimeSecs: event.data.startTimeSecs,
        endTimeSecs: event.data.endTimeSecs,
        unitId: event.data.unitId,
        routeIds: event.data.routeIds,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Streams live plan events from the CalendarService.
/// autoDispose ensures the gRPC stream closes when no widget is watching.
final planEventsProvider =
    StreamProvider.autoDispose<PlanEvent>((ref) {
  final stub = ref.watch(calendarServiceProvider);
  return stub.subscribePlans(SubscribePlansRequest());
});

/// Accumulates the plan event stream into a live list.
/// PLAN_ADDED / PLAN_UPDATED / PLAN_DELETED events are applied incrementally.
final plansProvider =
    StreamProvider.autoDispose<List<Plan>>((ref) async* {
  final events = ref.watch(planEventsProvider.stream);
  final plans = <int, Plan>{};

  // Emit empty list immediately so callers show "no plans" rather than an
  // infinite loading indicator while waiting for the first server event.
  yield [];

  await for (final event in events) {
    switch (event.type) {
      case PlanEventType.PLAN_ADDED:
      case PlanEventType.PLAN_UPDATED:
        plans[event.id] = Plan.fromEvent(event);
      case PlanEventType.PLAN_DELETED:
        plans.remove(event.id);
      default:
        break;
    }
    yield plans.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
});
