import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/widget_catalog.dart';

// ── Navigation channels ───────────────────────────────────────────────────────
// Qt→Flutter: Qt calls FlutterDesktopMessengerSend("navigation", utf8_route).
// Flutter→Qt: Flutter calls _backChannel.send('back') to return to Qt shell.
const _navigationChannel = BasicMessageChannel<String>(
  'navigation',
  StringCodec(),
);

/// Send this to ask Qt to hide Flutter and show the QML window again.
const backChannel = BasicMessageChannel<String>(
  'navigation/back',
  StringCodec(),
);

// ── Router ────────────────────────────────────────────────────────────────────
final _routerKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _routerKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const _PlaceholderScreen(),
    ),
    GoRoute(
      path: '/widget-catalog',
      builder: (_, __) => const WidgetCatalogScreen(),
    ),
    // Add migrated routes here as screens move from Qt to Flutter (Phase 2+).
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Listen for route requests from the Qt shell.
  _navigationChannel.setMessageHandler((String? route) async {
    if (route != null && route.isNotEmpty) {
      debugPrint('[Flutter] Navigation request from Qt: $route');
      _router.go(route);
    }
    return ''; // BasicMessageChannel<String> requires a non-null reply
  });

  runApp(const ProviderScope(child: EventCalendarApp()));
}

class EventCalendarApp extends StatelessWidget {
  const EventCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EventCalendar',
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}

/// Placeholder shown at "/" until the first real screen is migrated.
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
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Flutter embedded — Phase 1',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text(
              'Qt calls navBridge->navigateTo("/widget-catalog") to switch here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'View Widget Catalog',
              icon: Icons.widgets_outlined,
              onPressed: () => context.go('/widget-catalog'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Back to Qt',
              icon: Icons.arrow_back,
              onPressed: () => backChannel.send('back'),
            ),
          ],
        ),
      ),
    );
  }
}
