import 'package:core/core.dart'
    show unitsProvider, selectedWeekProvider, unitFilterProvider;

import 'plan_form_state.dart' show planFormProvider;
import 'package:design_system/design_system.dart' show AppScaffold;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/hours_footer.dart';
import 'widgets/plan_sidebar.dart';
import 'widgets/unit_filter_sidebar.dart';
import 'week_view.dart';

int _isoWeekNumber(DateTime date) {
  final thursday = date.add(Duration(days: 4 - date.weekday));
  final jan1     = DateTime(thursday.year, 1, 1);
  return (thursday.difference(jan1).inDays ~/ 7) + 1;
}

/// Top-level week calendar screen.
///
/// Composes [WeekView] + [PlanSidebar] side by side, with [HoursFooter] at
/// the bottom and week-navigation arrows in the AppBar.
///
/// [onBack] is called when the user taps the "Back to Qt" toolbar button.
/// Pass `null` to hide the button (e.g. in standalone Flutter mode).
class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart    = ref.watch(selectedWeekProvider);
    final weekNotifier = ref.read(selectedWeekProvider.notifier);
    final formNotifier = ref.read(planFormProvider.notifier);
    final unitsAsync   = ref.watch(unitsProvider);

    final weekNum = _isoWeekNumber(weekStart);

    // Show a badge on the filter icon when a filter is active.
    final filterActive = ref.watch(
        unitFilterProvider.select((f) => f.isNotEmpty));

    return AppScaffold(
      title: 'Week $weekNum',
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous week',
          onPressed: () =>
              weekNotifier.state = weekStart.subtract(const Duration(days: 7)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next week',
          onPressed: () =>
              weekNotifier.state = weekStart.add(const Duration(days: 7)),
        ),
        // Builder gives a context that is a descendant of the Scaffold,
        // required for Scaffold.of(ctx).openEndDrawer() to work.
        Builder(
          builder: (ctx) => IconButton(
            icon: Badge(
              isLabelVisible: filterActive,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter units',
            onPressed: () => Scaffold.of(ctx).openEndDrawer(),
          ),
        ),
        if (onBack != null)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Back to Qt',
            onPressed: onBack,
          ),
      ],
      body: Row(children: [
        Expanded(
          child: WeekView(
            onPlanTap: formNotifier.openForEdit,
          ),
        ),
        const PlanSidebar(),
      ]),
      bottomNavigationBar: const HoursFooter(),
      endDrawer: const UnitFilterSidebar(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add plan',
        onPressed: () {
          // Use the first available unit as the default; fall back to id=1
          // if units are still loading.
          final units   = unitsAsync.valueOrNull;
          final unitId  = (units?.isNotEmpty ?? false) ? units!.first.id : 1;
          formNotifier.openForNew(unitId: unitId, date: weekStart);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
