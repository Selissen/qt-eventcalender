import 'package:design_system/design_system.dart' show AppSpacing;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/plan_form_cubit.dart';
import 'plan_form.dart';

const double kSidebarWidth = 280.0;

/// Slide-in plan edit / add panel.
///
/// Rendered as a fixed-width column to the right of [WeekView].
/// Visible when [PlanFormCubit] state is [PlanFormOpen].
class PlanSidebar extends StatelessWidget {
  const PlanSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanFormCubit, PlanFormState>(
      builder: (context, state) {
        final isOpen = state is PlanFormOpen;

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
                      // ── Header ──────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xFFCCCCCC))),
                        ),
                        child: Row(children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            tooltip: 'Close',
                            onPressed: () =>
                                context.read<PlanFormCubit>().close(),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            state.planId == null ? 'Add Plan' : 'Edit Plan',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                      ),

                      // ── Form ────────────────────────────────────────────
                      const Expanded(child: PlanForm()),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
