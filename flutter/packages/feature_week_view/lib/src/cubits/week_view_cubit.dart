import 'dart:async';

import 'package:core/core.dart'
    show
        Plan,
        Unit,
        PlansCubit,
        PlansState,
        PlansLoaded,
        PlansError,
        UnitsCubit,
        UnitsState,
        UnitsLoaded,
        UnitsError,
        WeekRow,
        buildWeekGrid;
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

DateTime _mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

int _isoWeekNumber(DateTime date) {
  final thursday = date.add(Duration(days: 4 - date.weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  return (thursday.difference(jan1).inDays ~/ 7) + 1;
}

// ── State ─────────────────────────────────────────────────────────────────────

class WeekViewState {
  const WeekViewState({
    required this.selectedWeek,
    required this.unitFilter,
    required this.weekGrid,
    required this.isLoading,
    this.error,
  });

  final DateTime selectedWeek;
  final Set<int> unitFilter;
  final List<WeekRow> weekGrid;
  final bool isLoading;
  final Object? error;

  int get weekNumber => _isoWeekNumber(selectedWeek);

  factory WeekViewState.initial() => WeekViewState(
        selectedWeek: _mondayOf(DateTime.now()),
        unitFilter: const {},
        weekGrid: const [],
        isLoading: true,
      );

  WeekViewState copyWith({
    DateTime? selectedWeek,
    Set<int>? unitFilter,
    List<WeekRow>? weekGrid,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) =>
      WeekViewState(
        selectedWeek: selectedWeek ?? this.selectedWeek,
        unitFilter: unitFilter ?? this.unitFilter,
        weekGrid: weekGrid ?? this.weekGrid,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Manages the week calendar view: navigation, unit filter, and derived grid.
///
/// Subscribes to [PlansCubit] and [UnitsCubit] streams and recomputes the
/// week grid whenever plans, units, the selected week, or the filter changes.
class WeekViewCubit extends Cubit<WeekViewState> {
  WeekViewCubit({
    required PlansCubit plansCubit,
    required UnitsCubit unitsCubit,
  }) : super(WeekViewState.initial()) {
    // Sync from whatever state the upstream cubits are already in.
    final plansState = plansCubit.state;
    final unitsState = unitsCubit.state;
    if (plansState is PlansLoaded) _plans = plansState.plans;
    if (unitsState is UnitsLoaded) _units = unitsState.units;
    _recompute(state);

    // Subscribe to future changes.
    _plansSub = plansCubit.stream.listen(_onPlansChanged);
    _unitsSub = unitsCubit.stream.listen(_onUnitsChanged);
  }

  StreamSubscription<PlansState>? _plansSub;
  StreamSubscription<UnitsState>? _unitsSub;
  List<Plan> _plans = [];
  List<Unit>? _units; // null until first UnitsLoaded

  // ── Navigation ──────────────────────────────────────────────────────────────

  void nextWeek() => _recompute(
        state.copyWith(
          selectedWeek: state.selectedWeek.add(const Duration(days: 7)),
        ),
      );

  void prevWeek() => _recompute(
        state.copyWith(
          selectedWeek: state.selectedWeek.subtract(const Duration(days: 7)),
        ),
      );

  // ── Unit filter ─────────────────────────────────────────────────────────────

  /// Toggle [tapped] in the filter.
  ///
  /// When the filter is empty (show all) and the user unchecks a unit, the new
  /// filter becomes "all units except this one". When the resulting set equals
  /// all units, collapse back to empty (= show all).
  void toggleUnit(int tapped, Set<int> allIds) {
    final current = state.unitFilter;
    final Set<int> next;

    if (current.isEmpty) {
      next = allIds.difference({tapped});
    } else if (current.contains(tapped)) {
      next = current.difference({tapped});
    } else {
      next = {...current, tapped};
    }

    final newFilter = next.length == allIds.length ? <int>{} : next;
    _recompute(state.copyWith(unitFilter: newFilter));
  }

  void clearUnitFilter() => _recompute(state.copyWith(unitFilter: const {}));

  // ── Upstream listeners ───────────────────────────────────────────────────────

  void _onPlansChanged(PlansState plansState) {
    if (plansState is PlansLoaded) {
      _plans = plansState.plans;
      _recompute(state);
    } else if (plansState is PlansError) {
      emit(state.copyWith(isLoading: false, error: plansState.error));
    }
    // PlansLoading / PlansInitial: grid stays as-is while waiting.
  }

  void _onUnitsChanged(UnitsState unitsState) {
    if (unitsState is UnitsLoaded) {
      _units = unitsState.units;
      _recompute(state);
    } else if (unitsState is UnitsError) {
      emit(state.copyWith(isLoading: false, error: unitsState.error));
    }
  }

  // ── Grid computation ─────────────────────────────────────────────────────────

  void _recompute(WeekViewState base) {
    if (_units == null) {
      emit(base.copyWith(isLoading: true));
      return;
    }
    final visibleUnits = base.unitFilter.isEmpty
        ? _units!
        : _units!.where((u) => base.unitFilter.contains(u.id)).toList();
    final grid = buildWeekGrid(visibleUnits, _plans, base.selectedWeek);
    emit(base.copyWith(isLoading: false, weekGrid: grid, clearError: true));
  }

  @override
  Future<void> close() {
    _plansSub?.cancel();
    _unitsSub?.cancel();
    return super.close();
  }
}
