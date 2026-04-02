import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Route registry — add migrated routes here as screens move from Qt to Flutter.
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderScreen(),
    ),
  ],
);

void main() {
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

/// Placeholder screen shown in Phase 0 to validate the embedding works.
/// Replace with real migrated screens in Phase 1+.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EventCalendar — Flutter')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Flutter embedded successfully.',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 8),
            Text(
              'Phase 0 validation screen — replace with migrated Qt screens.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
