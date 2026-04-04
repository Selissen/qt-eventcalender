import 'package:core/core.dart' show Plan, PlanData, planMutationsProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── State model ───────────────────────────────────────────────────────────────

/// Transient state of the plan edit / add form.
///
/// [planId] is null in add-mode and non-null in edit-mode.
class PlanFormState {
  const PlanFormState({
    this.planId,
    required this.unitId,
    required this.startDateTime,
    required this.endDateTime,
    this.routeIds = const {},
    this.isSaving = false,
    this.saveError,
    this.endError,
  });

  final int?      planId;        // null = add mode
  final int       unitId;
  final DateTime  startDateTime;
  final DateTime  endDateTime;
  final Set<int>  routeIds;
  final bool      isSaving;
  final String?   saveError;     // error from RPC
  final String?   endError;      // inline "end must be after start"

  PlanFormState copyWith({
    int?      planId,
    bool      clearPlanId = false,
    int?      unitId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    Set<int>? routeIds,
    bool?     isSaving,
    String?   saveError,
    bool      clearSaveError = false,
    String?   endError,
    bool      clearEndError = false,
  }) => PlanFormState(
    planId:        clearPlanId ? null : (planId ?? this.planId),
    unitId:        unitId        ?? this.unitId,
    startDateTime: startDateTime ?? this.startDateTime,
    endDateTime:   endDateTime   ?? this.endDateTime,
    routeIds:      routeIds      ?? this.routeIds,
    isSaving:      isSaving      ?? this.isSaving,
    saveError:     clearSaveError ? null : (saveError ?? this.saveError),
    endError:      clearEndError  ? null : (endError  ?? this.endError),
  );

  /// Convenience: build a [PlanFormState] pre-filled from an existing plan.
  factory PlanFormState.fromPlan(Plan plan) {
    final start = DateTime.parse(plan.startDate);
    final end   = DateTime.parse(plan.endDate);
    return PlanFormState(
      planId:        plan.id,
      unitId:        plan.unitId,
      startDateTime: start.add(Duration(seconds: plan.startTimeSecs)),
      endDateTime:   end.add(Duration(seconds: plan.endTimeSecs)),
      routeIds:      plan.routeIds.toSet(),
    );
  }

  /// Convenience: build a default new-plan state for a given unit and date.
  factory PlanFormState.forNew({required int unitId, required DateTime date}) {
    final day = DateTime(date.year, date.month, date.day);
    return PlanFormState(
      unitId:        unitId,
      startDateTime: day.add(const Duration(hours: 9)),
      endDateTime:   day.add(const Duration(hours: 10)),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages the plan edit sidebar.  State is null when the sidebar is closed.
class PlanFormNotifier extends Notifier<PlanFormState?> {
  @override
  PlanFormState? build() => null;

  /// Open the sidebar in add-mode.
  void openForNew({required int unitId, required DateTime date}) {
    state = PlanFormState.forNew(unitId: unitId, date: date);
  }

  /// Open the sidebar in edit-mode pre-filled from [plan].
  void openForEdit(Plan plan) {
    state = PlanFormState.fromPlan(plan);
  }

  void close() => state = null;

  void updateUnitId(int id) =>
      state = state?.copyWith(unitId: id, clearEndError: true);

  void updateStart(DateTime dt) =>
      state = state?.copyWith(startDateTime: dt, clearEndError: true);

  void updateEnd(DateTime dt) =>
      state = state?.copyWith(endDateTime: dt, clearEndError: true);

  void toggleRoute(int routeId) {
    final current = state;
    if (current == null) return;
    final ids = Set<int>.from(current.routeIds);
    if (ids.contains(routeId)) ids.remove(routeId); else ids.add(routeId);
    state = current.copyWith(routeIds: ids);
  }

  /// Validates and submits the form via gRPC.  Closes the sidebar on success.
  Future<void> save() async {
    final current = state;
    if (current == null) return;

    if (!current.endDateTime.isAfter(current.startDateTime)) {
      state = current.copyWith(endError: 'End must be after start');
      return;
    }

    state = current.copyWith(
      isSaving: true,
      clearSaveError: true,
      clearEndError: true,
    );

    try {
      final mutations = ref.read(planMutationsProvider);
      final data = PlanData(
        name:          '',
        startDate:     _isoDate(current.startDateTime),
        startTimeSecs: _timeSecs(current.startDateTime),
        endDate:       _isoDate(current.endDateTime),
        endTimeSecs:   _timeSecs(current.endDateTime),
        unitId:        current.unitId,
        routeIds:      current.routeIds.toList(),
      );

      if (current.planId == null) {
        await mutations.add(data);
      } else {
        await mutations.update(current.planId!, data);
      }

      state = null; // close on success; stream delivers the updated plan list
    } catch (e) {
      state = state?.copyWith(
        isSaving: false,
        saveError: e.toString(),
      );
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// UI-scoped provider.  Override with [ProviderScope] at the [WeekScreen] level
/// so each screen instance gets its own independent sidebar state.
final planFormProvider =
    NotifierProvider<PlanFormNotifier, PlanFormState?>(() => PlanFormNotifier());

// ── Helpers ───────────────────────────────────────────────────────────────────

String _isoDate(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}'
    '-${dt.month.toString().padLeft(2, '0')}'
    '-${dt.day.toString().padLeft(2, '0')}';

int _timeSecs(DateTime dt) => dt.hour * 3600 + dt.minute * 60;
