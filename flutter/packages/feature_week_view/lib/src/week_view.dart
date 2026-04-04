import 'package:core/core.dart' show Plan, weekGridProvider, selectedWeekProvider;
import 'package:design_system/design_system.dart'
    show AppLoadingSpinner, AppErrorView, EmptyView;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/week_day_header.dart';
import 'widgets/week_grid_body.dart';

/// Full week view: fixed day-header + scrollable unit-band grid.
///
/// Watches [weekGridProvider] and [selectedWeekProvider] from [core].
/// [onPlanTap] is called when the user taps a filled plan chip.
class WeekView extends ConsumerWidget {
  const WeekView({super.key, this.onPlanTap});

  final ValueChanged<Plan>? onPlanTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridAsync = ref.watch(weekGridProvider);
    final weekStart = ref.watch(selectedWeekProvider);

    return Column(children: [
      WeekDayHeader(weekStart: weekStart),
      const Divider(height: 1, thickness: 1, color: Color(0xFFCCCCCC)),
      Expanded(
        child: gridAsync.when(
          loading: () => const AppLoadingSpinner(),
          error: (e, _) => AppErrorView(
            error: e,
            onRetry: () => ref.invalidate(weekGridProvider),
          ),
          data: (rows) => rows.isEmpty
              ? const EmptyView(
                  message: 'No units configured',
                  icon: Icons.grid_off_outlined,
                )
              : WeekGridBody(rows: rows, onPlanTap: onPlanTap),
        ),
      ),
    ]);
  }
}
