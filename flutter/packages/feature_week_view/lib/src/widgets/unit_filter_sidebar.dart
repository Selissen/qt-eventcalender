import 'package:core/core.dart' show unitsProvider, unitFilterProvider;
import 'package:design_system/design_system.dart'
    show AppColors, AppSpacing, AppLoadingSpinner, AppErrorView;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// End-drawer that lets the user choose which unit bands are visible.
///
/// Empty filter = show all (matches Qt UnitFilterSidebar behaviour).
/// Changes take effect immediately — no "Apply" step.
class UnitFilterSidebar extends ConsumerWidget {
  const UnitFilterSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final filter     = ref.watch(unitFilterProvider);
    final notifier   = ref.read(unitFilterProvider.notifier);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
              child: Row(children: [
                const Expanded(
                  child: Text(
                    'Filter Units',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: filter.isEmpty ? null : () => notifier.state = {},
                  child: const Text('Clear'),
                ),
              ]),
            ),
            const Divider(height: 1),

            // ── Unit list ─────────────────────────────────────────────────
            Expanded(
              child: unitsAsync.when(
                loading: () => const AppLoadingSpinner(),
                error: (e, _) => AppErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(unitsProvider),
                ),
                data: (units) {
                  if (units.isEmpty) {
                    return Center(
                      child: Text(
                        'No units configured',
                        style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: units.length,
                    itemBuilder: (context, i) {
                      final unit = units[i];
                      // Checked when: no filter active (show all) OR unit is in filter.
                      final checked = filter.isEmpty || filter.contains(unit.id);

                      return CheckboxListTile(
                        dense: true,
                        title: Text(unit.name),
                        value: checked,
                        onChanged: (_) => _toggle(
                          notifier: notifier,
                          current: filter,
                          allIds: units.map((u) => u.id).toSet(),
                          tapped: unit.id,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle [tapped] unit in the filter.
  ///
  /// When the filter is empty (show all) and the user unchecks a unit,
  /// the new filter becomes "all units except this one".
  /// When the resulting set equals all units, collapse back to empty (show all).
  static void _toggle({
    required StateController<Set<int>> notifier,
    required Set<int> current,
    required Set<int> allIds,
    required int tapped,
  }) {
    final Set<int> next;

    if (current.isEmpty) {
      // Currently showing all → hide the tapped unit.
      next = allIds.difference({tapped});
    } else if (current.contains(tapped)) {
      next = current.difference({tapped});
    } else {
      next = {...current, tapped};
    }

    // If the resulting set equals "all", collapse to empty (= show all).
    notifier.state = next.length == allIds.length ? {} : next;
  }
}
