import 'package:design_system/design_system.dart' show AppSpacing;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../plan_form_state.dart';
import 'plan_form.dart';

const double kSidebarWidth = 280.0;

/// Slide-in plan edit / add panel.
///
/// Rendered as a fixed-width column to the right of [WeekView].
/// Visible when [planFormProvider] state is non-null.
///
/// Wrap the screen body in a [Row]:
/// ```dart
/// Row(children: [
///   Expanded(child: WeekView(...)),
///   PlanSidebar(),
/// ])
/// ```
class PlanSidebar extends ConsumerWidget {
  const PlanSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(planFormProvider);
    final notifier  = ref.read(planFormProvider.notifier);

    final isOpen = formState != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isOpen ? kSidebarWidth : 0,
      child: isOpen
          ? Material(
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Color(0xFFCCCCCC))),
                    ),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        tooltip: 'Close',
                        onPressed: notifier.close,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        formState.planId == null ? 'Add Plan' : 'Edit Plan',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  ),

                  // ── Form ──────────────────────────────────────────────────
                  const Expanded(child: PlanForm()),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
