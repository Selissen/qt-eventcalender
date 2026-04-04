import 'package:core/core.dart' show Plan, WeekRow, HeaderRow, PlanRow;
import 'package:design_system/design_system.dart' show AppColors;
import 'package:flutter/material.dart';

import 'plan_cell.dart';
import 'week_day_header.dart' show kWeekRailWidth;

const double _kHeaderBandHeight = 26.0;
const Color  _kDivider          = Color(0xFFCCCCCC);

/// The scrollable body of the week grid.
///
/// Renders a [ListView] of [WeekRow] entries produced by [buildWeekGrid]:
///   [HeaderRow] → 26 px tinted unit-name band
///   [PlanRow]   → row of 7 [PlanCell] widgets
///
/// [onPlanTap] is forwarded to each [PlanCell]; pass null to disable tapping.
class WeekGridBody extends StatelessWidget {
  const WeekGridBody({
    super.key,
    required this.rows,
    this.onPlanTap,
  });

  final List<WeekRow> rows;
  final ValueChanged<Plan>? onPlanTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          HeaderRow() => _UnitHeaderBand(row: row),
          PlanRow()   => _PlanRowWidget(row: row, onPlanTap: onPlanTap),
        };
      },
    );
  }
}

// ── Unit header band ──────────────────────────────────────────────────────────

class _UnitHeaderBand extends StatelessWidget {
  const _UnitHeaderBand({required this.row});
  final HeaderRow row;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: _kHeaderBandHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        child: Row(children: [
          // Rail spacer aligns the text under the day columns, not the week number.
          const SizedBox(width: kWeekRailWidth),
          Expanded(
            child: Stack(children: [
              Positioned(left: 0, right: 0, bottom: 0,
                  child: Container(height: 1, color: _kDivider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    row.unitName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface.withValues(alpha: 0.7),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Plan row ──────────────────────────────────────────────────────────────────

class _PlanRowWidget extends StatelessWidget {
  const _PlanRowWidget({required this.row, this.onPlanTap});
  final PlanRow row;
  final ValueChanged<Plan>? onPlanTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Week-number rail spacer — keeps cells aligned with day header columns.
      const SizedBox(width: kWeekRailWidth),
      ...List.generate(7, (d) => Expanded(
        child: PlanCell(
          plan: row.dayPlans[d],
          onTap: onPlanTap,
        ),
      )),
    ]);
  }
}
