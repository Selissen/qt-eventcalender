import 'package:core/core.dart'
    show Plan, PlanData, CalendarRepository;
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class PlanFormState {
  const PlanFormState();
}

/// The sidebar is closed — no form is shown.
final class PlanFormClosed extends PlanFormState {
  const PlanFormClosed();
}

/// The sidebar is open, either in add-mode ([planId] == null) or edit-mode.
final class PlanFormOpen extends PlanFormState {
  const PlanFormOpen({
    this.planId,
    required this.unitId,
    required this.startDateTime,
    required this.endDateTime,
    this.routeIds = const {},
    this.isSaving = false,
    this.saveError,
    this.endError,
  });

  final int? planId; // null = add mode
  final int unitId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final Set<int> routeIds;
  final bool isSaving;
  final String? saveError;
  final String? endError;

  PlanFormOpen copyWith({
    int? planId,
    bool clearPlanId = false,
    int? unitId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    Set<int>? routeIds,
    bool? isSaving,
    String? saveError,
    bool clearSaveError = false,
    String? endError,
    bool clearEndError = false,
  }) =>
      PlanFormOpen(
        planId: clearPlanId ? null : (planId ?? this.planId),
        unitId: unitId ?? this.unitId,
        startDateTime: startDateTime ?? this.startDateTime,
        endDateTime: endDateTime ?? this.endDateTime,
        routeIds: routeIds ?? this.routeIds,
        isSaving: isSaving ?? this.isSaving,
        saveError: clearSaveError ? null : (saveError ?? this.saveError),
        endError: clearEndError ? null : (endError ?? this.endError),
      );
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Manages the plan edit / add sidebar.
///
/// State is [PlanFormClosed] when the sidebar is hidden, [PlanFormOpen]
/// when it is visible.  On successful save the cubit returns to
/// [PlanFormClosed]; the live [PlansCubit] stream delivers the update.
class PlanFormCubit extends Cubit<PlanFormState> {
  PlanFormCubit(this._repository) : super(const PlanFormClosed());

  final CalendarRepository _repository;

  // ── Open / close ────────────────────────────────────────────────────────────

  void openForNew({required int unitId, required DateTime date}) {
    final day = DateTime(date.year, date.month, date.day);
    emit(PlanFormOpen(
      unitId: unitId,
      startDateTime: day.add(const Duration(hours: 9)),
      endDateTime: day.add(const Duration(hours: 10)),
    ));
  }

  void openForEdit(Plan plan) {
    final start = DateTime.parse(plan.startDate);
    final end = DateTime.parse(plan.endDate);
    emit(PlanFormOpen(
      planId: plan.id,
      unitId: plan.unitId,
      startDateTime: start.add(Duration(seconds: plan.startTimeSecs)),
      endDateTime: end.add(Duration(seconds: plan.endTimeSecs)),
      routeIds: plan.routeIds.toSet(),
    ));
  }

  void close() => emit(const PlanFormClosed());

  // ── Field updates ────────────────────────────────────────────────────────────

  void updateUnitId(int id) {
    final s = state;
    if (s is! PlanFormOpen) return;
    emit(s.copyWith(unitId: id, clearEndError: true));
  }

  void updateStart(DateTime dt) {
    final s = state;
    if (s is! PlanFormOpen) return;
    emit(s.copyWith(startDateTime: dt, clearEndError: true));
  }

  void updateEnd(DateTime dt) {
    final s = state;
    if (s is! PlanFormOpen) return;
    emit(s.copyWith(endDateTime: dt, clearEndError: true));
  }

  void toggleRoute(int routeId) {
    final s = state;
    if (s is! PlanFormOpen) return;
    final ids = Set<int>.from(s.routeIds);
    if (ids.contains(routeId)) {
      ids.remove(routeId);
    } else {
      ids.add(routeId);
    }
    emit(s.copyWith(routeIds: ids));
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  /// Validates and submits the form via gRPC. Closes the sidebar on success.
  Future<void> save() async {
    final s = state;
    if (s is! PlanFormOpen) return;

    if (!s.endDateTime.isAfter(s.startDateTime)) {
      emit(s.copyWith(endError: 'End must be after start'));
      return;
    }

    emit(s.copyWith(isSaving: true, clearSaveError: true, clearEndError: true));

    try {
      final data = PlanData(
        name: '',
        startDate: _isoDate(s.startDateTime),
        startTimeSecs: _timeSecs(s.startDateTime),
        endDate: _isoDate(s.endDateTime),
        endTimeSecs: _timeSecs(s.endDateTime),
        unitId: s.unitId,
        routeIds: s.routeIds.toList(),
      );

      if (s.planId == null) {
        await _repository.addPlan(data);
      } else {
        await _repository.updatePlan(s.planId!, data);
      }

      emit(const PlanFormClosed()); // stream delivers the updated plan list
    } catch (e) {
      final current = state;
      if (current is PlanFormOpen) {
        emit(current.copyWith(isSaving: false, saveError: e.toString()));
      }
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _isoDate(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}'
    '-${dt.month.toString().padLeft(2, '0')}'
    '-${dt.day.toString().padLeft(2, '0')}';

int _timeSecs(DateTime dt) => dt.hour * 3600 + dt.minute * 60;
