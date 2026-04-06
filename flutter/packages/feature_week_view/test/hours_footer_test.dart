// Widget tests for HoursFooter.
//
// Verifies that the BLoC-driven footer correctly:
//   - stays hidden while data is loading
//   - shows per-unit hours and a grand total once all cubits have data
//   - respects the unit filter from WeekViewCubit
//   - deduplicates multi-day plans (same plan id should not be double-counted)
//   - excludes plans outside the currently displayed week
import 'package:core/core.dart'
    show
        CalendarRepository,
        Plan,
        PlansCubit,
        PlansInitial,
        PlansLoaded,
        UnitsCubit,
        UnitsLoaded;
import 'package:core/src/proto/calendar.pb.dart' show Unit;
import 'package:design_system/design_system.dart' show GTheme;
import 'package:feature_week_view/src/cubits/week_view_cubit.dart';
import 'package:feature_week_view/src/widgets/hours_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake cubits ───────────────────────────────────────────────────────────────
//
// CalendarRepository owns a lazy gRPC ClientChannel — no network connection is
// made until an RPC is called, so constructing one with a dummy host is safe in
// tests.  We subclass the real cubits so BlocProvider<UnitsCubit> etc. resolve
// correctly; we emit the desired state immediately and never call load().

CalendarRepository _dummyRepo() => CalendarRepository(host: 'test-host');

/// UnitsCubit that immediately emits [UnitsLoaded] with [units].
class _LoadedUnitsCubit extends UnitsCubit {
  _LoadedUnitsCubit(List<Unit> units) : super(_dummyRepo()) {
    emit(UnitsLoaded(units));
  }
}

/// PlansCubit that immediately emits [PlansLoaded] with [plans].
class _LoadedPlansCubit extends PlansCubit {
  _LoadedPlansCubit(List<Plan> plans) : super(_dummyRepo()) {
    emit(PlansLoaded(plans));
  }
}

/// PlansCubit that stays in [PlansInitial] (simulates loading).
class _LoadingPlansCubit extends PlansCubit {
  _LoadingPlansCubit() : super(_dummyRepo());
  // Inherits PlansInitial from PlansCubit super-constructor; never calls subscribe().
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns the Monday of the current week (same logic as WeekViewCubit.initial).
DateTime _currentMonday() {
  final d = DateTime.now();
  final today = DateTime(d.year, d.month, d.day);
  return today.subtract(Duration(days: today.weekday - 1));
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '-${d.month.toString().padLeft(2, '0')}'
    '-${d.day.toString().padLeft(2, '0')}';

Unit _unit(int id, String name) => Unit(id: id, name: name);

Plan _plan({
  required int id,
  required int unitId,
  required DateTime date,
  DateTime? endDate,
  int startTimeSecs = 0,
  int endTimeSecs = 3600,
}) =>
    Plan(
      id: id,
      name: '',
      startDate: _iso(date),
      endDate: _iso(endDate ?? date),
      startTimeSecs: startTimeSecs,
      endTimeSecs: endTimeSecs,
      unitId: unitId,
      routeIds: [],
    );

Widget _buildFooter({
  required UnitsCubit unitsCubit,
  required PlansCubit plansCubit,
  required WeekViewCubit weekCubit,
}) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<UnitsCubit>.value(value: unitsCubit),
        BlocProvider<PlansCubit>.value(value: plansCubit),
        BlocProvider<WeekViewCubit>.value(value: weekCubit),
      ],
      child: MaterialApp(
        theme: GTheme.light(),
        home: const Scaffold(body: HoursFooter()),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final monday = _currentMonday();

  group('HoursFooter', () {
    testWidgets('hidden while plans are loading', (tester) async {
      final unitsCubit = _LoadedUnitsCubit([_unit(1, 'Alpha')]);
      final plansCubit = _LoadingPlansCubit(); // stays in PlansInitial
      final weekCubit  = WeekViewCubit(
        plansCubit: plansCubit,
        unitsCubit: unitsCubit,
      );

      await tester.pumpWidget(
          _buildFooter(unitsCubit: unitsCubit, plansCubit: plansCubit, weekCubit: weekCubit));

      expect(find.text('Total'), findsNothing);
    });

    testWidgets('shows per-unit hours and grand total', (tester) async {
      // Alpha: 2 h plan; Beta: 1 h plan → Total: 3 h.
      final p1 = _plan(id: 1, unitId: 1, date: monday,
          startTimeSecs: 0, endTimeSecs: 7200);
      final p2 = _plan(id: 2, unitId: 2, date: monday,
          startTimeSecs: 0, endTimeSecs: 3600);

      final unitsCubit = _LoadedUnitsCubit([_unit(1, 'Alpha'), _unit(2, 'Beta')]);
      final plansCubit = _LoadedPlansCubit([p1, p2]);
      final weekCubit  = WeekViewCubit(
        plansCubit: plansCubit,
        unitsCubit: unitsCubit,
      );

      await tester.pumpWidget(
          _buildFooter(unitsCubit: unitsCubit, plansCubit: plansCubit, weekCubit: weekCubit));

      expect(find.text('Alpha'),  findsOneWidget);
      expect(find.text('Beta'),   findsOneWidget);
      expect(find.text('2.0 h'), findsOneWidget);
      expect(find.text('1.0 h'), findsOneWidget);
      expect(find.text('Total'),  findsOneWidget);
      expect(find.text('3.0 h'), findsOneWidget);
    });

    testWidgets('no plans → shows 0.0 h for all columns', (tester) async {
      final unitsCubit = _LoadedUnitsCubit([_unit(1, 'Alpha')]);
      final plansCubit = _LoadedPlansCubit([]);
      final weekCubit  = WeekViewCubit(
        plansCubit: plansCubit,
        unitsCubit: unitsCubit,
      );

      await tester.pumpWidget(
          _buildFooter(unitsCubit: unitsCubit, plansCubit: plansCubit, weekCubit: weekCubit));

      // Alpha column + Total column both show 0.0 h.
      expect(find.text('0.0 h'), findsNWidgets(2));
    });

    testWidgets('plans outside the current week are excluded', (tester) async {
      final nextMonday = monday.add(const Duration(days: 7));
      final plan = _plan(
        id: 1, unitId: 1, date: nextMonday, // next week
        startTimeSecs: 0, endTimeSecs: 3600,
      );

      final unitsCubit = _LoadedUnitsCubit([_unit(1, 'Alpha')]);
      final plansCubit = _LoadedPlansCubit([plan]);
      final weekCubit  = WeekViewCubit(
        plansCubit: plansCubit,
        unitsCubit: unitsCubit,
      );

      await tester.pumpWidget(
          _buildFooter(unitsCubit: unitsCubit, plansCubit: plansCubit, weekCubit: weekCubit));

      expect(find.text('0.0 h'), findsNWidgets(2));
    });

    testWidgets('unit filter hides excluded units', (tester) async {
      final p1 = _plan(id: 1, unitId: 1, date: monday,
          startTimeSecs: 0, endTimeSecs: 3600); // Alpha: 1 h
      final p2 = _plan(id: 2, unitId: 2, date: monday,
          startTimeSecs: 0, endTimeSecs: 7200); // Beta: 2 h (should be hidden)

      final unitsCubit = _LoadedUnitsCubit([_unit(1, 'Alpha'), _unit(2, 'Beta')]);
      final plansCubit = _LoadedPlansCubit([p1, p2]);
      final weekCubit  = WeekViewCubit(
        plansCubit: plansCubit,
        unitsCubit: unitsCubit,
      );

      // Filter to Alpha only (exclude Beta id=2).
      weekCubit.toggleUnit(2, {1, 2});

      await tester.pumpWidget(
          _buildFooter(unitsCubit: unitsCubit, plansCubit: plansCubit, weekCubit: weekCubit));

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'),  findsNothing);
      // Alpha 1.0 h and Total 1.0 h (Beta excluded).
      expect(find.text('1.0 h'), findsNWidgets(2));
      expect(find.text('2.0 h'), findsNothing);
    });

    testWidgets('multi-day plan counted once, not per day', (tester) async {
      // Plan spans Mon–Wed; duration 2 h.  Should appear once in hours total.
      final wednesday = monday.add(const Duration(days: 2));
      final plan = _plan(
        id: 1, unitId: 1,
        date: monday, endDate: wednesday,
        startTimeSecs: 0, endTimeSecs: 7200, // 2 h
      );

      final unitsCubit = _LoadedUnitsCubit([_unit(1, 'Alpha')]);
      final plansCubit = _LoadedPlansCubit([plan]);
      final weekCubit  = WeekViewCubit(
        plansCubit: plansCubit,
        unitsCubit: unitsCubit,
      );

      await tester.pumpWidget(
          _buildFooter(unitsCubit: unitsCubit, plansCubit: plansCubit, weekCubit: weekCubit));

      // 2.0 h for Alpha and 2.0 h Total — exactly two occurrences.
      expect(find.text('2.0 h'), findsNWidgets(2));
    });
  });
}
