import 'package:core/core.dart'
    show unitsProvider, weekPlansProvider, unitFilterProvider;
import 'package:design_system/design_system.dart' show AppColors, AppSpacing;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom bar showing planned hours per visible unit and a grand total.
///
/// Matches Qt's PlanFooter.qml: two rows (unit names above, hours below),
/// one column per visible unit plus a Total column on the right.
///
/// Hidden when the plan stream is still loading.
class HoursFooter extends ConsumerWidget {
  const HoursFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final plansAsync = ref.watch(weekPlansProvider);
    final filter     = ref.watch(unitFilterProvider);

    // Don't render until both are available.
    return unitsAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (allUnits) => plansAsync.when(
        loading: () => const SizedBox.shrink(),
        error:   (_, __) => const SizedBox.shrink(),
        data: (plans) {
          final visibleUnits = filter.isEmpty
              ? allUnits
              : allUnits.where((u) => filter.contains(u.id)).toList();

          if (visibleUnits.isEmpty) return const SizedBox.shrink();

          // Hours per unit.
          final hoursMap = <int, double>{
            for (final u in visibleUnits) u.id: 0.0,
          };
          for (final plan in plans) {
            if (hoursMap.containsKey(plan.unitId)) {
              hoursMap[plan.unitId] = hoursMap[plan.unitId]! +
                  (plan.endTimeSecs - plan.startTimeSecs) / 3600.0;
            }
          }
          final total = hoursMap.values.fold(0.0, (a, b) => a + b);

          return DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFCCCCCC))),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(children: [
                // One column per visible unit.
                ...visibleUnits.map((unit) => Expanded(
                  child: _FooterCell(
                    label: unit.name,
                    value: '${hoursMap[unit.id]!.toStringAsFixed(1)} h',
                    bold: false,
                  ),
                )),
                // Total column.
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
      ),
    );
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
            color: AppColors.onSurface.withValues(alpha: 0.6),
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
