import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'screens/map_component.dart' show MapComponentApp;

// ── Navigation channels ───────────────────────────────────────────────────────
// Qt→Flutter: Qt calls FlutterDesktopMessengerSend("navigation", utf8_route).
// Flutter→Qt: Flutter calls backChannel.send('back') to return to Qt shell.
const _navigationChannel = BasicMessageChannel<String>(
  'navigation',
  StringCodec(),
);

/// Send this to ask Qt to hide Flutter and show the QML window again.
const backChannel = BasicMessageChannel<String>(
  'navigation/back',
  StringCodec(),
);

/// Entry point used by ComponentEngineFactory for the embedded map component.
/// Must live in main.dart (the root library) for the AOT linker to find it by name.
@pragma('vm:entry-point')
void mapComponentMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MapComponentApp());
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Full navigation-bridge mode: Qt controls which screen is shown.
  _navigationChannel.setMessageHandler((String? route) async {
    if (route != null && route.isNotEmpty) {
      debugPrint('[Flutter] Navigation request from Qt: $route');
      appRouter.go(route);
    }
    return '';
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
      routerConfig: appRouter,
    );
  }
}
