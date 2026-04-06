import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapComponentApp extends StatelessWidget {
  const MapComponentApp({super.key, required this.instanceId});

  final String instanceId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MapComponentScreen(instanceId: instanceId),
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
  const MapComponentScreen({super.key, required this.instanceId});

  /// Unique identifier for this map component instance.
  /// The bridge channel will be "com.eventcalendar/map/<instanceId>",
  /// matching what FlutterComponentView computes on the C++ side.
  final String instanceId;

  @override
  State<MapComponentScreen> createState() => _MapComponentScreenState();
}

class _MapComponentScreenState extends State<MapComponentScreen> {
  final _mapController = MapController();
  late final _binding = FlutterComponentBinding(
    channel: 'com.eventcalendar/map/${widget.instanceId}',
    onMessage: _handleMessage,
  );

  List<_RoutePoint> _routes = [];
  Set<int> _selectedIds = {};

  static const _defaultCenter = LatLng(52.3, 5.3);
  static const _defaultZoom = 7.5;

  @override
  void initState() {
    super.initState();
    _binding.init();
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  Future<void> _handleMessage(String method, Map<String, dynamic> args) async {
    if (method == 'setRoutes') {
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
  }

  void _toggleRoute(int routeId) {
    setState(() {
      if (_selectedIds.contains(routeId)) {
        _selectedIds.remove(routeId);
      } else {
        _selectedIds.add(routeId);
      }
    });
    _binding.send('toggleRoute', {'id': routeId});
  }

  void _fitCamera(List<_RoutePoint> routes, Set<int> selectedIds) {
    final targets = selectedIds.isEmpty
        ? routes
        : routes.where((r) => selectedIds.contains(r.id)).toList();
    if (targets.isEmpty) return;

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
              child: GestureDetector(
                onTap: () => _toggleRoute(r.id),
                child: Tooltip(
                  message: r.name,
                  child: Icon(
                    Icons.location_on,
                    color: selected ? Colors.red.shade700 : Colors.grey.shade500,
                    size: selected ? 40 : 28,
                  ),
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
