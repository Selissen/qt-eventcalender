import 'package:core/core.dart' show unitsProvider, routesProvider;
import 'package:design_system/design_system.dart'
    show AppColors, AppSpacing, AppLoadingSpinner;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../plan_form_state.dart';

/// The edit / add form for a single plan.
///
/// Watches [planFormProvider] for its state and calls notifier methods on
/// every interaction.  The parent [PlanSidebar] controls visibility.
class PlanForm extends ConsumerWidget {
  const PlanForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(planFormProvider);
    if (formState == null) return const SizedBox.shrink();

    final notifier   = ref.read(planFormProvider.notifier);
    final unitsAsync = ref.watch(unitsProvider);
    final routesAsync = ref.watch(routesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Unit ───────────────────────────────────────────────────────────
          const Text('Unit',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          unitsAsync.when(
            loading: () => const AppLoadingSpinner(),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
            data: (units) => DropdownButtonFormField<int>(
              // key forces rebuild when a different plan is opened, so
              // initialValue is honoured even though the widget stays in tree.
              key: ValueKey('unit_${formState.planId}_${formState.unitId}'),
              initialValue: units.any((u) => u.id == formState.unitId)
                  ? formState.unitId
                  : (units.isNotEmpty ? units.first.id : null),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: units.map((u) => DropdownMenuItem(
                value: u.id,
                child: Text(u.name),
              )).toList(),
              onChanged: (id) { if (id != null) notifier.updateUnitId(id); },
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Start ──────────────────────────────────────────────────────────
          const Text('Start',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          _DateTimeTile(
            dateTime: formState.startDateTime,
            onChanged: notifier.updateStart,
          ),

          const SizedBox(height: AppSpacing.md),

          // ── End ────────────────────────────────────────────────────────────
          const Text('End',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          _DateTimeTile(
            dateTime: formState.endDateTime,
            onChanged: notifier.updateEnd,
          ),
          if (formState.endError != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(formState.endError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],

          const SizedBox(height: AppSpacing.md),

          // ── Routes ─────────────────────────────────────────────────────────
          const Text('Routes (optional)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          routesAsync.when(
            loading: () => const AppLoadingSpinner(),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
            data: (routes) => routes.isEmpty
                ? Text('No routes configured',
                    style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.45),
                        fontSize: 12))
                : DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: routes.map((r) => CheckboxListTile(
                        dense: true,
                        title: Text(r.name, style: const TextStyle(fontSize: 13)),
                        value: formState.routeIds.contains(r.id),
                        onChanged: (_) => notifier.toggleRoute(r.id),
                        controlAffinity: ListTileControlAffinity.leading,
                      )).toList(),
                    ),
                  ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Save error ─────────────────────────────────────────────────────
          if (formState.saveError != null) ...[
            Text(formState.saveError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12)),
            const SizedBox(height: AppSpacing.sm),
          ],

          // ── Actions ────────────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: formState.isSaving ? null : notifier.close,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: formState.isSaving ? null : notifier.save,
                child: formState.isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
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
      date.year, date.month, date.day,
      time.hour, time.minute,
    ));
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
