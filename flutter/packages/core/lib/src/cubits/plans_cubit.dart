import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../proto/calendar.pb.dart';
import '../repository/calendar_repository.dart';

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

// ── State ─────────────────────────────────────────────────────────────────────

sealed class PlansState {
  const PlansState();
}

final class PlansInitial extends PlansState {
  const PlansInitial();
}

final class PlansLoading extends PlansState {
  const PlansLoading();
}

final class PlansLoaded extends PlansState {
  const PlansLoaded(this.plans);
  final List<Plan> plans;
}

final class PlansError extends PlansState {
  const PlansError(this.error);
  final Object error;
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Subscribes to the CalendarService gRPC stream and accumulates plan events
/// into a sorted live list.
///
/// Call [subscribe] once (done automatically from [EventCalendarApp]).
/// The stream stays open until the cubit is closed.
class PlansCubit extends Cubit<PlansState> {
  PlansCubit(this._repository) : super(const PlansInitial());

  final CalendarRepository _repository;
  StreamSubscription<PlanEvent>? _sub;
  final _plans = <int, Plan>{};

  void subscribe() {
    _sub?.cancel();
    _plans.clear();
    emit(const PlansLoading());

    // Emit empty list immediately so callers show "no plans" rather than an
    // infinite loading indicator while waiting for the first server event.
    emit(const PlansLoaded([]));

    _sub = _repository.subscribePlans().listen(
      _onEvent,
      onError: (Object e) => emit(PlansError(e)),
    );
  }

  void _onEvent(PlanEvent event) {
    switch (event.type) {
      case PlanEventType.PLAN_ADDED:
      case PlanEventType.PLAN_UPDATED:
        _plans[event.id] = Plan.fromEvent(event);
      case PlanEventType.PLAN_DELETED:
        _plans.remove(event.id);
      default:
        return;
    }
    final sorted = _plans.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    emit(PlansLoaded(sorted));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
