import 'cubits/plans_cubit.dart' show Plan;
import 'proto/calendar.pb.dart' show Unit;

// ── Row types ─────────────────────────────────────────────────────────────────

sealed class WeekRow {}

/// The tinted unit-name band that starts each unit block.
class HeaderRow extends WeekRow {
  HeaderRow({required this.unitId, required this.unitName});
  final int unitId;
  final String unitName;
}

/// One slot row: seven cells, one per day.  A cell is null when empty.
class PlanRow extends WeekRow {
  PlanRow({required this.unitId, required this.slotIndex, required this.dayPlans});
  final int unitId;
  final int slotIndex;
  final List<Plan?> dayPlans; // length == 7
}

// ── Algorithm ─────────────────────────────────────────────────────────────────

/// Converts a flat plan list into the row structure used by the week grid.
///
/// Direct port of CalendarUtils::buildWeekGrid (calendarutils.cpp).
///
/// [units]     — ordered list of units to display (already filtered if needed).
/// [plans]     — all plans that overlap the displayed week.
/// [weekStart] — Monday (or locale first-day) of the displayed week; time ignored.
///
/// Returns a flat list of [HeaderRow] / [PlanRow] entries:
///   HeaderRow  — unit name band
///   PlanRow    — one slot row per concurrent lane, minimum one per unit
List<WeekRow> buildWeekGrid(
  List<Unit> units,
  List<Plan> plans,
  DateTime weekStart,
) {
  final ws = DateTime(weekStart.year, weekStart.month, weekStart.day);

  // Annotate each plan with its day-index range within the displayed week.
  final entries = <_Entry>[];
  for (final plan in plans) {
    final startDate = DateTime.parse(plan.startDate);
    final endDate   = DateTime.parse(plan.endDate);
    final startDi   = startDate.difference(ws).inDays.clamp(0, 6);
    final endDi     = endDate.difference(ws).inDays.clamp(0, 6);
    entries.add(_Entry(plan: plan, startDi: startDi, endDi: endDi));
  }

  // Group plans by unit, deduplicating multi-day plans by plan id.
  final byUnit = <int, Map<int, _Entry>>{};
  for (final unit in units) {
    byUnit[unit.id] = {};
  }
  for (final e in entries) {
    if (byUnit.containsKey(e.plan.unitId)) {
      byUnit[e.plan.unitId]![e.plan.id] = e;
    }
  }

  final rows = <WeekRow>[];

  for (final unit in units) {
    rows.add(HeaderRow(unitId: unit.id, unitName: unit.name));

    // Sort unit's plans: by startDi, then endDi.
    final unitPlans = byUnit[unit.id]!.values.toList()
      ..sort((a, b) {
        final c = a.startDi.compareTo(b.startDi);
        return c != 0 ? c : a.endDi.compareTo(b.endDi);
      });

    // Greedy interval scheduling: place each plan in the first lane where it
    // doesn't overlap the last plan already in that lane.
    final lanes = <List<_Entry>>[];
    for (final plan in unitPlans) {
      bool placed = false;
      for (final lane in lanes) {
        if (plan.startDi > lane.last.endDi) {
          lane.add(plan);
          placed = true;
          break;
        }
      }
      if (!placed) lanes.add([plan]);
    }

    final numLanes = lanes.isEmpty ? 1 : lanes.length;
    for (var s = 0; s < numLanes; s++) {
      final dayPlans = List<Plan?>.filled(7, null);
      if (s < lanes.length) {
        for (final e in lanes[s]) {
          for (var d = e.startDi; d <= e.endDi; d++) {
            dayPlans[d] = e.plan;
          }
        }
      }
      rows.add(PlanRow(unitId: unit.id, slotIndex: s, dayPlans: dayPlans));
    }
  }

  return rows;
}

// ── Internal helper ───────────────────────────────────────────────────────────

class _Entry {
  const _Entry({required this.plan, required this.startDi, required this.endDi});
  final Plan plan;
  final int startDi;
  final int endDi;
}
