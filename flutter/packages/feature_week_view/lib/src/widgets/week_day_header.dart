import 'package:flutter/material.dart';

const double kHeaderHeight = 52.0;
const double kWeekRailWidth = 32.0;
const Color  _kDivider = Color(0xFFCCCCCC);

const List<String> _kDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

int _isoWeekNumber(DateTime date) {
  // ISO 8601: the week containing the first Thursday is week 1.
  final thursday = date.add(Duration(days: 4 - date.weekday));
  final jan1     = DateTime(thursday.year, 1, 1);
  return (thursday.difference(jan1).inDays ~/ 7) + 1;
}

/// Fixed day-header row + week-number rail.
///
/// Rendered above the scrollable grid body; never scrolls.
class WeekDayHeader extends StatelessWidget {
  const WeekDayHeader({super.key, required this.weekStart});

  /// The Monday (or locale first-day) of the displayed week.
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final today     = DateTime.now();
    final weekNum   = _isoWeekNumber(weekStart);
    final primary   = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      height: kHeaderHeight,
      child: Row(children: [
        // ── Week number rail ────────────────────────────────────────────────
        SizedBox(
          width: kWeekRailWidth,
          child: Center(
            child: Text(
              '$weekNum',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),

        // ── Seven day columns ───────────────────────────────────────────────
        Expanded(
          child: Stack(children: [
            // Bottom divider
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(height: 1, color: _kDivider),
            ),

            Row(children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final isToday = day.year  == today.year
                           && day.month == today.month
                           && day.day   == today.day;

              return Expanded(
                child: Stack(alignment: Alignment.center, children: [
                  // Left divider (skip for first column)
                  if (i > 0)
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Container(width: 1, color: _kDivider),
                    ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _kDayNames[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _DayNumber(
                        day: day.day,
                        isToday: isToday,
                        primary: primary,
                        onPrimary: onPrimary,
                      ),
                    ],
                  ),
                ]),
              );
            })),
          ]),
        ),
      ]),
    );
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.primary,
    required this.onPrimary,
  });

  final int day;
  final bool isToday;
  final Color primary;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    return SizedBox(
      width: size, height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isToday ? primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? onPrimary : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
