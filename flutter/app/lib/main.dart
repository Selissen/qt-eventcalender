import 'package:core/core.dart'
    show CalendarRepository, PlansCubit, UnitsCubit, RoutesCubit;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  runApp(const EventCalendarApp());
}

class EventCalendarApp extends StatefulWidget {
  const EventCalendarApp({super.key});

  @override
  State<EventCalendarApp> createState() => _EventCalendarAppState();
}

class _EventCalendarAppState extends State<EventCalendarApp> {
  late final CalendarRepository _repository;
  late final PlansCubit _plansCubit;
  late final UnitsCubit _unitsCubit;
  late final RoutesCubit _routesCubit;

  @override
  void initState() {
    super.initState();
    _repository = CalendarRepository();
    _plansCubit = PlansCubit(_repository)..subscribe();
    _unitsCubit = UnitsCubit(_repository)..load();
    _routesCubit = RoutesCubit(_repository)..load();
  }

  @override
  void dispose() {
    _plansCubit.close();
    _unitsCubit.close();
    _routesCubit.close();
    _repository.shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CalendarRepository>.value(value: _repository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PlansCubit>.value(value: _plansCubit),
          BlocProvider<UnitsCubit>.value(value: _unitsCubit),
          BlocProvider<RoutesCubit>.value(value: _routesCubit),
        ],
        child: MaterialApp.router(
          title: 'EventCalendar',
          theme: buildAppTheme(),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
