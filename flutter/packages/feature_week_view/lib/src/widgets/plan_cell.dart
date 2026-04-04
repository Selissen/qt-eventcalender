import 'package:core/core.dart' show Plan;
import 'package:design_system/design_system.dart' show AppColors;
import 'package:flutter/material.dart';

// ── Layout constants matching the Qt WeekPlanCell ─────────────────────────────

const double kCellHeight = 52.0;
const Color  _kGridLine  = Color(0xFFE0E0E0);

String _formatSecs(int secs) {
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// A single slot cell in the week grid.
///
/// Shows a coloured plan chip when [plan] is non-null; otherwise renders empty
/// grid space with hairline borders — matching Qt's WeekPlanCell.qml exactly.
class PlanCell extends StatelessWidget {
  const PlanCell({super.key, required this.plan, this.onTap});

  final Plan? plan;
  final ValueChanged<Plan>? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kCellHeight,
      child: Stack(children: [
        // ── Grid lines ────────────────────────────────────────────────────
        Positioned(right: 0, top: 0, bottom: 0,
            child: Container(width: 1, color: _kGridLine)),
        Positioned(left: 0, right: 0, bottom: 0,
            child: Container(height: 1, color: _kGridLine)),

        // ── Plan chip ─────────────────────────────────────────────────────
        if (plan != null)
          Positioned.fill(
            top: 3, bottom: 3, left: 3, right: 3,
            child: GestureDetector(
              onTap: () => onTap?.call(plan!),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 4, 5, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan!.name.isNotEmpty ? plan!.name : 'Unit ${plan!.unitId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        '${_formatSecs(plan!.startTimeSecs)} – ${_formatSecs(plan!.endTimeSecs)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
