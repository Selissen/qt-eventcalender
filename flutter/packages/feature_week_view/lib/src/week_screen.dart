import 'package:core/core.dart'
    show CalendarRepository, PlansCubit, UnitsCubit, UnitsLoaded;
import 'package:design_system/design_system.dart' show AppScaffold;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubits/plan_form_cubit.dart';
import 'cubits/week_view_cubit.dart';
import 'widgets/hours_footer.dart';
import 'widgets/plan_sidebar.dart';
import 'widgets/unit_filter_sidebar.dart';
import 'week_view.dart';

/// Top-level week calendar screen.
///
/// Provides [WeekViewCubit] and [PlanFormCubit] scoped to this screen, then
/// delegates layout to [_WeekScreenBody].
///
/// [onBack] is called when the user taps the "Back to Qt" toolbar button.
/// Pass `null` to hide the button (e.g. in standalone Flutter mode).
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => WeekViewCubit(
            plansCubit: ctx.read<PlansCubit>(),
            unitsCubit: ctx.read<UnitsCubit>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => PlanFormCubit(ctx.read<CalendarRepository>()),
        ),
      ],
      child: _WeekScreenBody(onBack: onBack),
    );
  }
}

class _WeekScreenBody extends StatelessWidget {
  const _WeekScreenBody({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekViewCubit, WeekViewState>(
      builder: (context, state) {
        final weekCubit = context.read<WeekViewCubit>();
        final formCubit = context.read<PlanFormCubit>();

        return AppScaffold(
          title: 'Week ${state.weekNumber}',
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous week',
              onPressed: weekCubit.prevWeek,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next week',
              onPressed: weekCubit.nextWeek,
            ),
            // Builder gives a context that is a descendant of the Scaffold,
            // required for Scaffold.of(ctx).openEndDrawer() to work.
            Builder(
              builder: (ctx) => IconButton(
                icon: Badge(
                  isLabelVisible: state.unitFilter.isNotEmpty,
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
              child: WeekView(onPlanTap: formCubit.openForEdit),
            ),
            const PlanSidebar(),
          ]),
          bottomNavigationBar: const HoursFooter(),
          endDrawer: const UnitFilterSidebar(),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add plan',
            onPressed: () {
              final unitsState = context.read<UnitsCubit>().state;
              final units = unitsState is UnitsLoaded ? unitsState.units : null;
              final unitId =
                  (units?.isNotEmpty ?? false) ? units!.first.id : 1;
              formCubit.openForNew(unitId: unitId, date: state.selectedWeek);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
