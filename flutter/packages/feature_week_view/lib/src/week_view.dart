import 'package:core/core.dart' show Plan, PlansCubit, UnitsCubit;
import 'package:design_system/design_system.dart'
    show AppLoadingSpinner, AppErrorView, EmptyView;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubits/week_view_cubit.dart';
import 'widgets/week_day_header.dart';
import 'widgets/week_grid_body.dart';

/// Full week view: fixed day-header + scrollable unit-band grid.
///
/// Watches [WeekViewCubit] for grid data and navigation state.
/// [onPlanTap] is called when the user taps a filled plan chip.
class WeekView extends StatelessWidget {
  const WeekView({super.key, this.onPlanTap});

  final ValueChanged<Plan>? onPlanTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekViewCubit, WeekViewState>(
      builder: (context, state) {
        return Column(children: [
          WeekDayHeader(weekStart: state.selectedWeek),
          const Divider(height: 1, thickness: 1, color: Color(0xFFCCCCCC)),
          Expanded(
            child: state.isLoading
                ? const AppLoadingSpinner()
                : state.error != null
                    ? AppErrorView(
                        error: state.error!,
                        onRetry: () {
                          context.read<UnitsCubit>().load(force: true);
                          context.read<PlansCubit>().subscribe();
                        },
                      )
                    : state.weekGrid.isEmpty
                        ? const EmptyView(
                            message: 'No units configured',
                            icon: Icons.grid_off_outlined,
                          )
                        : WeekGridBody(
                            rows: state.weekGrid,
                            onPlanTap: onPlanTap,
                          ),
          ),
        ]);
      },
    );
  }
}
