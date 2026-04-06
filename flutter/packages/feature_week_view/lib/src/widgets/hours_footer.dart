import 'package:core/core.dart'
    show
        Plan,
        PlansCubit,
        PlansState,
        PlansLoaded,
        UnitsCubit,
        UnitsState,
        UnitsLoaded;
import 'package:design_system/design_system.dart' show GTokens;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/week_view_cubit.dart';

/// Bottom bar showing planned hours per visible unit and a grand total.
///
/// Matches Qt's PlanFooter.qml: two rows (unit names above, hours below),
/// one column per visible unit plus a Total column on the right.
///
/// Hidden when the plan stream is still loading.
class HoursFooter extends StatelessWidget {
  const HoursFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnitsCubit, UnitsState>(
      builder: (context, unitsState) {
        if (unitsState is! UnitsLoaded) return const SizedBox.shrink();
        final allUnits = unitsState.units;

        return BlocBuilder<WeekViewCubit, WeekViewState>(
          builder: (context, weekState) {
            return BlocBuilder<PlansCubit, PlansState>(
              builder: (context, plansState) {
                if (plansState is! PlansLoaded) return const SizedBox.shrink();

                final filter = weekState.unitFilter;
                final visibleUnits = filter.isEmpty
                    ? allUnits
                    : allUnits.where((u) => filter.contains(u.id)).toList();

                if (visibleUnits.isEmpty) return const SizedBox.shrink();

                // Filter plans to current week.
                final weekStart = weekState.selectedWeek;
                final weekEnd = weekStart.add(const Duration(days: 6));
                final weekPlans = _plansForWeek(
                    plansState.plans, weekStart, weekEnd);

                // Hours per unit (deduplicate multi-day plans by id).
                final hoursMap = <int, double>{
                  for (final u in visibleUnits) u.id: 0.0,
                };
                final seen = <int>{};
                for (final plan in weekPlans) {
                  if (!seen.add(plan.id)) continue;
                  if (hoursMap.containsKey(plan.unitId)) {
                    hoursMap[plan.unitId] = hoursMap[plan.unitId]! +
                        (plan.endTimeSecs - plan.startTimeSecs) / 3600.0;
                  }
                }
                final total =
                    hoursMap.values.fold(0.0, (a, b) => a + b);

                return DecoratedBox(
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: Color(0xFFCCCCCC))),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: GTokens.space1),
                    child: Row(children: [
                      ...visibleUnits.map((unit) => Expanded(
                            child: _FooterCell(
                              label: unit.name,
                              value:
                                  '${hoursMap[unit.id]!.toStringAsFixed(1)} h',
                              bold: false,
                            ),
                          )),
                      Expanded(
                        child: _FooterCell(
                          label: 'Total',
                          value: '${total.toStringAsFixed(1)} h',
                          bold: true,
                        ),
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Returns plans that overlap the given week [start]–[end] (inclusive).
  List<Plan> _plansForWeek(
      List<Plan> plans, DateTime start, DateTime end) {
    return plans.where((p) {
      final planStart = DateTime.parse(p.startDate);
      final planEnd = DateTime.parse(p.endDate);
      return !planEnd.isBefore(start) && !planStart.isAfter(end);
    }).toList();
  }
}

class _FooterCell extends StatelessWidget {
  const _FooterCell({
    required this.label,
    required this.value,
    required this.bold,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
