import 'package:core/core.dart'
    show
        UnitsCubit,
        UnitsState,
        UnitsLoaded,
        RoutesCubit,
        RoutesState,
        RoutesLoaded;
import 'package:design_system/design_system.dart'
    show AppColors, AppSpacing, AppLoadingSpinner;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/plan_form_cubit.dart';

/// The edit / add form for a single plan.
///
/// Watches [PlanFormCubit] for form state and dispatches updates on every
/// interaction. The parent [PlanSidebar] controls visibility.
class PlanForm extends StatelessWidget {
  const PlanForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanFormCubit, PlanFormState>(
      builder: (context, formState) {
        if (formState is! PlanFormOpen) return const SizedBox.shrink();
        final cubit = context.read<PlanFormCubit>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Unit ──────────────────────────────────────────────────
              const Text('Unit',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              BlocBuilder<UnitsCubit, UnitsState>(
                builder: (context, unitsState) => switch (unitsState) {
                  UnitsLoaded(:final units) => DropdownButtonFormField<int>(
                      // key forces rebuild when a different plan is opened.
                      key: ValueKey(
                          'unit_${formState.planId}_${formState.unitId}'),
                      initialValue:
                          units.any((u) => u.id == formState.unitId)
                              ? formState.unitId
                              : (units.isNotEmpty ? units.first.id : null),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: units
                          .map((u) => DropdownMenuItem(
                              value: u.id, child: Text(u.name)))
                          .toList(),
                      onChanged: (id) {
                        if (id != null) cubit.updateUnitId(id);
                      },
                    ),
                  _ => const AppLoadingSpinner(),
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Start ─────────────────────────────────────────────────
              const Text('Start',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              _DateTimeTile(
                  dateTime: formState.startDateTime,
                  onChanged: cubit.updateStart),

              const SizedBox(height: AppSpacing.md),

              // ── End ───────────────────────────────────────────────────
              const Text('End',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              _DateTimeTile(
                  dateTime: formState.endDateTime,
                  onChanged: cubit.updateEnd),
              if (formState.endError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(formState.endError!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ],

              const SizedBox(height: AppSpacing.md),

              // ── Routes ────────────────────────────────────────────────
              const Text('Routes (optional)',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              BlocBuilder<RoutesCubit, RoutesState>(
                builder: (context, routesState) => switch (routesState) {
                  RoutesLoaded(:final routes) => routes.isEmpty
                      ? Text(
                          'No routes configured',
                          style: TextStyle(
                              color: AppColors.onSurface
                                  .withValues(alpha: 0.45),
                              fontSize: 12),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: routes
                                .map((r) => CheckboxListTile(
                                      dense: true,
                                      title: Text(r.name,
                                          style: const TextStyle(
                                              fontSize: 13)),
                                      value: formState.routeIds
                                          .contains(r.id),
                                      onChanged: (_) =>
                                          cubit.toggleRoute(r.id),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    ))
                                .toList(),
                          ),
                        ),
                  _ => const AppLoadingSpinner(),
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Save error ────────────────────────────────────────────
              if (formState.saveError != null) ...[
                Text(formState.saveError!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
                const SizedBox(height: AppSpacing.sm),
              ],

              // ── Actions ───────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: formState.isSaving ? null : cubit.close,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: formState.isSaving ? null : cubit.save,
                    child: formState.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ── Date / time picker tile ───────────────────────────────────────────────────

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.dateTime, required this.onChanged});

  final DateTime dateTime;
  final ValueChanged<DateTime> onChanged;

  String _label() {
    final d = dateTime;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  $h:$m';
  }

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dateTime),
    );
    if (time == null) return;

    onChanged(DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(_label()),
      onPressed: () => _pick(context),
    );
  }
}
