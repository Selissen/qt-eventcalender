import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Reusable helper that wires a Flutter component to the Qt host via a
/// [BasicMessageChannel].
///
/// Protocol (both directions are JSON strings):
///   Qt → Flutter: {"method": "someMethod", "args": {...}}
///   Flutter → Qt: {"method": "ready"}          — sent automatically on first frame
///                 {"method": "someEvent", "args": {...}}  — sent via [send]
///
/// Usage inside a [State.initState]:
///   ```dart
///   late final _binding = FlutterComponentBinding(
///     channel: 'com.eventcalendar/my-component',
///     onMessage: _handleMessage,
///   );
///
///   @override
///   void initState() {
///     super.initState();
///     _binding.init();
///   }
///
///   @override
///   void dispose() {
///     _binding.dispose();
///     super.dispose();
///   }
///
///   Future<void> _handleMessage(String method, Map<String, dynamic> args) async {
///     if (method == 'setData') { ... }
///   }
///   ```
class FlutterComponentBinding {
  FlutterComponentBinding({
    required this.channel,
    required this.onMessage,
  }) : _ch = BasicMessageChannel<String>(channel, const StringCodec());

  final String channel;

  /// Called for every message received from Qt (except the internal "ready"
  /// ping, which is handled automatically).
  final Future<void> Function(String method, Map<String, dynamic> args) onMessage;

  final BasicMessageChannel<String> _ch;

  /// Register the channel handler and send the "ready" ping after the first
  /// frame.  Call this from [State.initState].
  void init() {
    _ch.setMessageHandler(_handle);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _ch.send(jsonEncode({'method': 'ready'}));
    });
  }

  /// Send a message to the Qt host.
  void send(String method, [Map<String, dynamic> args = const {}]) {
    _ch.send(jsonEncode({'method': method, 'args': args}));
  }

  /// Unregister the channel handler.  Call this from [State.dispose].
  void dispose() {
    _ch.setMessageHandler(null);
  }

  Future<String> _handle(String? message) async {
    if (message == null) return '';
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final method = data['method'] as String? ?? '';
      final args = (data['args'] as Map<String, dynamic>?) ?? {};
      await onMessage(method, args);
    } catch (e) {
      // ignore: avoid_print
      print('[$channel] Failed to handle message: $e');
    }
    return '';
  }
}
