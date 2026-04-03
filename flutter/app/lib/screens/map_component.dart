import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show BasicMessageChannel, StringCodec;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Bidirectional channel with the Qt host.
// Qt → Flutter: {"method":"setRoutes","args":{...}}
// Flutter → Qt: {"method":"ready"}  (sent once on startup so Qt knows to flush routes)
const _mapChannel = BasicMessageChannel<String>(
  'com.eventcalendar/map',
  StringCodec(),
);

class MapComponentApp extends StatelessWidget {
  const MapComponentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapComponentScreen(),
    );
  }
}

class _RoutePoint {
  final int id;
  final String name;
  final LatLng position;
  const _RoutePoint(
      {required this.id, required this.name, required this.position});
}

class MapComponentScreen extends StatefulWidget {
  const MapComponentScreen({super.key});

  @override
  State<MapComponentScreen> createState() => _MapComponentScreenState();
}

class _MapComponentScreenState extends State<MapComponentScreen> {
  final _mapController = MapController();

  List<_RoutePoint> _routes = [];
  Set<int> _selectedIds = {};

  // Netherlands centre — shown before any routes are received.
  static const _defaultCenter = LatLng(52.3, 5.3);
  static const _defaultZoom = 7.5;

  @override
  void initState() {
    super.initState();
    _mapChannel.setMessageHandler(_onMessage);

    // Tell Qt the Dart handler is registered and it can now send routes.
    // Schedule after the first frame so the map widget is fully initialised
    // before we attempt any camera operations.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _mapChannel.send('{"method":"ready"}');
    });
  }

  @override
  void dispose() {
    _mapChannel.setMessageHandler(null);
    super.dispose();
  }

  Future<String> _onMessage(String? message) async {
    if (message == null) return '';
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['method'] == 'setRoutes') {
        final args = data['args'] as Map<String, dynamic>;
        final routes = (args['routes'] as List).map((r) {
          final m = r as Map<String, dynamic>;
          return _RoutePoint(
            id: m['id'] as int,
            name: m['name'] as String,
            position: LatLng(
              (m['lat'] as num).toDouble(),
              (m['lng'] as num).toDouble(),
            ),
          );
        }).toList();
        final selectedIds =
            (args['selectedIds'] as List).map((e) => e as int).toSet();

        setState(() {
          _routes = routes;
          _selectedIds = selectedIds;
        });

        _fitCamera(routes, selectedIds);
      }
    } catch (e) {
      debugPrint('[MapComponent] Failed to parse message: $e');
    }
    return '';
  }

  void _fitCamera(List<_RoutePoint> routes, Set<int> selectedIds) {
    final targets = selectedIds.isEmpty
        ? routes
        : routes.where((r) => selectedIds.contains(r.id)).toList();
    if (targets.isEmpty) return;

    // Defer camera move to next frame — MapController throws StateError if the
    // map widget has not been laid out yet (e.g. message arrived very early).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (targets.length == 1) {
          _mapController.move(targets.first.position, 12.0);
        } else {
          _mapController.fitCamera(CameraFit.coordinates(
            coordinates: targets.map((r) => r.position).toList(),
            padding: const EdgeInsets.all(48),
          ));
        }
      } catch (e) {
        debugPrint('[MapComponent] fitCamera failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.eventcalendar.app',
        ),
        MarkerLayer(
          markers: _routes.map((r) {
            final selected = _selectedIds.contains(r.id);
            return Marker(
              point: r.position,
              width: selected ? 40 : 32,
              height: selected ? 40 : 32,
              child: Tooltip(
                message: r.name,
                child: Icon(
                  Icons.location_on,
                  color: selected ? Colors.red.shade700 : Colors.grey.shade500,
                  size: selected ? 40 : 28,
                ),
              ),
            );
          }).toList(),
        ),
        if (_routes.isEmpty)
          const Align(
            alignment: Alignment.center,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Select routes to see them on the map'),
              ),
            ),
          ),
      ],
    );
  }
}
