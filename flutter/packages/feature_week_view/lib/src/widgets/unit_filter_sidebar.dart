import 'package:core/core.dart'
    show UnitsCubit, UnitsState, UnitsInitial, UnitsLoading, UnitsLoaded, UnitsError;
import 'package:design_system/design_system.dart'
    show AppLoadingSpinner, AppErrorView, GTokens;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/week_view_cubit.dart';

/// End-drawer that lets the user choose which unit bands are visible.
///
/// Empty filter = show all (matches Qt UnitFilterSidebar behaviour).
/// Changes take effect immediately — no "Apply" step.
class UnitFilterSidebar extends StatelessWidget {
  const UnitFilterSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            BlocBuilder<WeekViewCubit, WeekViewState>(
              builder: (context, weekState) => Padding(
                padding: const EdgeInsets.fromLTRB(
                    GTokens.space4, GTokens.space4, GTokens.space2, GTokens.space1),
                child: Row(children: [
                  const Expanded(
                    child: Text(
                      'Filter Units',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: weekState.unitFilter.isEmpty
                        ? null
                        : () => context.read<WeekViewCubit>().clearUnitFilter(),
                    child: const Text('Clear'),
                  ),
                ]),
              ),
            ),
            const Divider(height: 1),

            // ── Unit list ────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<UnitsCubit, UnitsState>(
                builder: (context, unitsState) => switch (unitsState) {
                  UnitsInitial() || UnitsLoading() => const AppLoadingSpinner(),
                  UnitsError(:final error) => AppErrorView(
                      error: error,
                      onRetry: () =>
                          context.read<UnitsCubit>().load(force: true),
                    ),
                  UnitsLoaded(:final units) =>
                    BlocBuilder<WeekViewCubit, WeekViewState>(
                      builder: (context, weekState) {
                        if (units.isEmpty) {
                          return Center(
                            child: Text(
                              'No units configured',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                          );
                        }
                        final filter = weekState.unitFilter;
                        final allIds = units.map((u) => u.id).toSet();
                        return ListView.builder(
                          itemCount: units.length,
                          itemBuilder: (context, i) {
                            final unit = units[i];
                            final checked =
                                filter.isEmpty || filter.contains(unit.id);
                            return CheckboxListTile(
                              dense: true,
                              title: Text(unit.name),
                              value: checked,
                              onChanged: (_) => context
                                  .read<WeekViewCubit>()
                                  .toggleUnit(unit.id, allIds),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                            );
                          },
                        );
                      },
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
