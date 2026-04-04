import 'package:feature_plans/feature_plans.dart';
import 'package:feature_week_view/feature_week_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/widget_catalog.dart';
import 'main.dart' show backChannel;

// ── Route registry ────────────────────────────────────────────────────────────
// Add a GoRoute here for each screen migrated from Qt.
// Update NavigationBridge::flutter_routes in C++ to match.

final routerKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: routerKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const _PlaceholderScreen(),
    ),

    // ── Tier 1 migrated screens ──────────────────────────────────────────────
    // (none yet — add dashboard, settings etc. here)

    // ── Tier 2 migrated screens ──────────────────────────────────────────────
    GoRoute(
      path: '/plans',
      builder: (_, _) => const PlansScreen(),
    ),
    GoRoute(
      path: '/week',
      builder: (_, _) => WeekScreen(onBack: () => backChannel.send('back')),
    ),

    // ── Dev / catalog ────────────────────────────────────────────────────────
    GoRoute(
      path: '/widget-catalog',
      builder: (_, _) => const WidgetCatalogScreen(),
    ),
  ],
);

/// Placeholder shown at "/" until the first real screen is migrated to this slot.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EventCalendar — Flutter')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64,
                color: Colors.green),
            const SizedBox(height: 16),
            const Text('Flutter embedded — Phase 1 + 2',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('Plans (migrated screen)'),
              onPressed: () => context.go('/plans'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_view_week),
              label: const Text('Week View (migrated screen)'),
              onPressed: () => context.go('/week'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.widgets_outlined),
              label: const Text('Widget Catalog'),
              onPressed: () => context.go('/widget-catalog'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Qt'),
              onPressed: () => backChannel.send('back'),
            ),
          ],
        ),
      ),
    );
  }
}
