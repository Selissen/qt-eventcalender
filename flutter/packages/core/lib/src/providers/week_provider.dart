import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../week_grid.dart';
import '../proto/calendar.pb.dart' show Unit;
import 'plans_provider.dart' show Plan, plansProvider;
import 'units_provider.dart' show unitsProvider;

// ── Navigation state ──────────────────────────────────────────────────────────

DateTime _mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  // DateTime.weekday: Mon=1 … Sun=7
  return d.subtract(Duration(days: d.weekday - 1));
}

/// The Monday that starts the currently displayed week.
final selectedWeekProvider = StateProvider<DateTime>(
  (ref) => _mondayOf(DateTime.now()),
);

// ── Unit filter ───────────────────────────────────────────────────────────────

/// IDs of units the user has chosen to show.  Empty = show all.
final unitFilterProvider = StateProvider<Set<int>>((ref) => {});

// ── Derived providers ─────────────────────────────────────────────────────────

/// Plans that fall within the displayed week, derived from the live stream.
///
/// Returns the same [AsyncValue] shape as [plansProvider] so callers handle
/// loading / error uniformly.
final weekPlansProvider = Provider.autoDispose<AsyncValue<List<Plan>>>((ref) {
  final allPlans   = ref.watch(plansProvider);
  final weekStart  = ref.watch(selectedWeekProvider);
  final weekEnd    = weekStart.add(const Duration(days: 6));

  return allPlans.whenData((plans) => plans.where((p) {
    final start = DateTime.parse(p.startDate);
    final end   = DateTime.parse(p.endDate);
    // A plan overlaps the week if it starts on or before weekEnd
    // and ends on or after weekStart.
    return !start.isAfter(weekEnd) && !end.isBefore(weekStart);
  }).toList());
});

/// The fully-built week grid, ready for the UI.
///
/// Returns [AsyncValue] so the screen can show loading / error states while
/// the unit list or plan stream is still pending.
final weekGridProvider = Provider.autoDispose<AsyncValue<List<WeekRow>>>((ref) {
  final unitsAsync = ref.watch(unitsProvider);
  final plansAsync = ref.watch(weekPlansProvider);
  final filter     = ref.watch(unitFilterProvider);

  // Propagate loading / error from either upstream.
  if (unitsAsync is AsyncLoading || plansAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  if (unitsAsync is AsyncError) return AsyncValue.error(
    unitsAsync.error, unitsAsync.stackTrace!,
  );
  if (plansAsync is AsyncError) return AsyncValue.error(
    plansAsync.error, plansAsync.stackTrace!,
  );

  final allUnits = unitsAsync.value!;
  final plans    = plansAsync.value!;
  final weekStart = ref.watch(selectedWeekProvider);

  // Apply unit filter (empty = show all).
  final List<Unit> visibleUnits = filter.isEmpty
      ? allUnits
      : allUnits.where((u) => filter.contains(u.id)).toList();

  return AsyncValue.data(buildWeekGrid(visibleUnits, plans, weekStart));
});
