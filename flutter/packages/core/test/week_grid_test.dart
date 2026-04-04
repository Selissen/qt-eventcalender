import 'package:core/src/week_grid.dart';
import 'package:core/src/providers/plans_provider.dart';
import 'package:core/src/proto/calendar.pb.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Unit _unit(int id, String name) => Unit(id: id, name: name);

Plan _plan({
  required int id,
  required int unitId,
  required String startDate,
  String? endDate,
  int startTimeSecs = 0,
  int endTimeSecs   = 3600,
}) => Plan(
  id:             id,
  name:           '',
  startDate:      startDate,
  endDate:        endDate ?? startDate,
  startTimeSecs:  startTimeSecs,
  endTimeSecs:    endTimeSecs,
  unitId:         unitId,
  routeIds:       [],
);

final _monday = DateTime(2026, 4, 6); // a known Monday

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('buildWeekGrid', () {
    test('no units → empty row list', () {
      final rows = buildWeekGrid([], [], _monday);
      expect(rows, isEmpty);
    });

    test('one unit, no plans → header + one empty PlanRow', () {
      final rows = buildWeekGrid([_unit(1, 'Alpha')], [], _monday);

      expect(rows.length, 2);
      expect(rows[0], isA<HeaderRow>());
      expect((rows[0] as HeaderRow).unitName, 'Alpha');

      final planRow = rows[1] as PlanRow;
      expect(planRow.slotIndex, 0);
      expect(planRow.dayPlans.every((p) => p == null), isTrue);
    });

    test('one plan on Monday fills day 0, rest are null', () {
      final plan = _plan(id: 1, unitId: 1, startDate: '2026-04-06');
      final rows = buildWeekGrid([_unit(1, 'Alpha')], [plan], _monday);

      final planRow = rows[1] as PlanRow;
      expect(planRow.dayPlans[0], isNotNull);
      expect(planRow.dayPlans[0]!.id, 1);
      for (var d = 1; d < 7; d++) {
        expect(planRow.dayPlans[d], isNull);
      }
    });

    test('multi-day plan fills its entire range', () {
      // Plan spans Mon–Wed (days 0–2)
      final plan = _plan(
        id: 1, unitId: 1,
        startDate: '2026-04-06',
        endDate:   '2026-04-08',
      );
      final rows = buildWeekGrid([_unit(1, 'Alpha')], [plan], _monday);

      final planRow = rows[1] as PlanRow;
      expect(planRow.dayPlans[0], isNotNull);
      expect(planRow.dayPlans[1], isNotNull);
      expect(planRow.dayPlans[2], isNotNull);
      expect(planRow.dayPlans[3], isNull);
    });

    test('two non-overlapping plans share one lane', () {
      // Mon plan and Wed plan — no overlap, fit in one lane.
      final p1 = _plan(id: 1, unitId: 1, startDate: '2026-04-06');
      final p2 = _plan(id: 2, unitId: 1, startDate: '2026-04-08');
      final rows = buildWeekGrid([_unit(1, 'Alpha')], [p1, p2], _monday);

      // Header + 1 PlanRow (both plans fit in one lane).
      expect(rows.length, 2);
      final planRow = rows[1] as PlanRow;
      expect(planRow.dayPlans[0]!.id, 1);
      expect(planRow.dayPlans[2]!.id, 2);
    });

    test('two overlapping plans produce two lanes', () {
      // Both plans on Monday — they overlap, need separate lanes.
      final p1 = _plan(id: 1, unitId: 1, startDate: '2026-04-06');
      final p2 = _plan(id: 2, unitId: 1, startDate: '2026-04-06');
      final rows = buildWeekGrid([_unit(1, 'Alpha')], [p1, p2], _monday);

      // Header + 2 PlanRows
      expect(rows.length, 3);
      expect(rows[1], isA<PlanRow>());
      expect(rows[2], isA<PlanRow>());
    });

    test('plans from a different unit are ignored for unit 1', () {
      final p = _plan(id: 1, unitId: 2, startDate: '2026-04-06');
      final rows = buildWeekGrid([_unit(1, 'Alpha')], [p], _monday);

      // Only unit 1 is listed; its plan row should be empty.
      final planRow = rows[1] as PlanRow;
      expect(planRow.dayPlans.every((c) => c == null), isTrue);
    });

    test('two units produce independent bands', () {
      final p1 = _plan(id: 1, unitId: 1, startDate: '2026-04-06');
      final p2 = _plan(id: 2, unitId: 2, startDate: '2026-04-07');
      final rows = buildWeekGrid(
        [_unit(1, 'Alpha'), _unit(2, 'Beta')],
        [p1, p2],
        _monday,
      );

      // Alpha: header + 1 PlanRow; Beta: header + 1 PlanRow = 4 rows
      expect(rows.length, 4);
      expect((rows[0] as HeaderRow).unitName, 'Alpha');
      expect((rows[1] as PlanRow).dayPlans[0]!.id, 1);
      expect((rows[2] as HeaderRow).unitName, 'Beta');
      expect((rows[3] as PlanRow).dayPlans[1]!.id, 2);
    });

    test('plan outside the week does not crash (clamping)', () {
      // Plan entirely before the week — clamped startDi == endDi == 0,
      // still placed without error.
      final p = _plan(id: 1, unitId: 1, startDate: '2026-03-30');
      expect(() => buildWeekGrid([_unit(1, 'A')], [p], _monday), returnsNormally);
    });

    test('duplicate plan id is deduplicated', () {
      // Same plan id twice in the input (can happen when a multi-day plan
      // appears in multiple daily query results).
      final p1 = _plan(id: 1, unitId: 1, startDate: '2026-04-06');
      final p2 = _plan(id: 1, unitId: 1, startDate: '2026-04-06');
      final rows = buildWeekGrid([_unit(1, 'Alpha')], [p1, p2], _monday);

      // Only one lane expected (dedup → one plan).
      expect(rows.length, 2);
    });
  });
}
