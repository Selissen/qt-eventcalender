import 'package:core/core.dart' show Plan, PlansCubit, PlansState, PlansLoaded;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Live plans list screen — migrated from Qt's PlanFooter + EventSidebar.
///
/// Data flows via [PlansCubit] which subscribes to the CalendarService
/// SubscribePlans gRPC stream. The stream stays open app-wide.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: BlocBuilder<PlansCubit, PlansState>(
        builder: (context, state) => switch (state) {
          PlansLoaded(:final plans) => plans.isEmpty
              ? const EmptyView(
                  message: 'No plans yet',
                  icon: Icons.event_note_outlined,
                )
              : _PlansList(plans: plans),
          _ => const AppLoadingSpinner(),
        },
      ),
    );
  }
}

class _PlansList extends StatelessWidget {
  const _PlansList({required this.plans});
  final List<Plan> plans;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(GTokens.space4),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: GTokens.space2),
      itemBuilder: (context, i) => _PlanCard(plan: plans[i]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final Plan plan;

  String _formatTime(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(GTokens.space4),
        child: Row(children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: GTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.startDate}  ${_formatTime(plan.startTimeSecs)} – ${_formatTime(plan.endTimeSecs)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (plan.name.isNotEmpty)
                  Text(plan.name,
                      style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          Text('Unit ${plan.unitId}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.secondary)),
        ]),
      ),
    );
  }
}
