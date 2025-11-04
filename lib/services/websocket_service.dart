// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Lightweight WebSocket scaffolding to support:
/// - Real-time appointment updates (accept/reschedule/cancel/assign driver)
/// - Real-time availability updates (slot changes)
///
/// This service exposes typed broadcast streams you can listen to from providers.
class WebSocketService {
  final Uri serverUri;
  WebSocketChannel? _channel;

  // Typed broadcast streams
  final StreamController<Map<String, dynamic>> _appointmentEventsCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _availabilityEventsCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<void> _connectedCtrl =
      StreamController<void>.broadcast();
  final StreamController<void> _disconnectedCtrl =
      StreamController<void>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get appointmentEvents =>
      _appointmentEventsCtrl.stream;
  Stream<Map<String, dynamic>> get availabilityEvents =>
      _availabilityEventsCtrl.stream;
  Stream<void> get connected => _connectedCtrl.stream;
  Stream<void> get disconnected => _disconnectedCtrl.stream;

  bool get isConnected => _channel != null;

  WebSocketService(String url) : serverUri = Uri.parse(url);

  Future<void> connect({Map<String, dynamic>? auth}) async {
    if (_channel != null) return;
    try {
      _channel = WebSocketChannel.connect(serverUri);
      _connectedCtrl.add(null);

      _channel!.stream.listen(
        (raw) {
          try {
            final msg = _decode(raw);
            final type = (msg['type'] ?? '').toString();

            switch (type) {
              // Expected messages for appointments:
              // { "type": "appointment_updated", "data": { ...appointment... } }
              // { "type": "appointment_created", "data": { ...appointment... } }
              // { "type": "appointment_deleted", "data": { "id": 123 } }
              case 'appointment_updated':
              case 'appointment_created':
              case 'appointment_deleted':
                _appointmentEventsCtrl.add(msg);
                break;

              // Expected messages for availability:
              // { "type": "availability_update", "data": { "date": "YYYY-MM-DD", "slots": [...] } }
              case 'availability_update':
                _availabilityEventsCtrl.add(msg);
                break;

              default:
                debugPrint(
                  'WebSocketService: Unrecognized message type: $type',
                );
            }
          } catch (e) {
            debugPrint('WebSocketService: Error parsing message: $e');
          }
        },
        onDone: () {
          _disconnectedCtrl.add(null);
          _teardownChannel();
        },
        onError: (e) {
          debugPrint('WebSocketService: stream error: $e');
          _disconnectedCtrl.add(null);
          _teardownChannel();
        },
        cancelOnError: true,
      );

      // Optionally send an auth/hello message
      if (auth != null && auth.isNotEmpty) {
        send({'type': 'hello', 'data': auth});
      }

      // Subscribe to topics by default
      subscribe(topic: 'appointments');
      subscribe(topic: 'availability');
    } catch (e) {
      debugPrint('WebSocketService: connection error: $e');
      _teardownChannel();
      rethrow;
    }
  }

  void _teardownChannel() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void send(Map<String, dynamic> message) {
    if (_channel == null) {
      debugPrint('WebSocketService: cannot send, not connected');
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('WebSocketService: send error: $e');
    }
  }

  void subscribe({required String topic, Map<String, dynamic>? params}) {
    send({
      'type': 'subscribe',
      'data': {'topic': topic, ...?params},
    });
  }

  void unsubscribe({required String topic}) {
    send({
      'type': 'unsubscribe',
      'data': {'topic': topic},
    });
  }

  Future<void> disconnect() async {
    _teardownChannel();
  }

  dynamic _decode(dynamic raw) {
    if (raw is String) return jsonDecode(raw);
    if (raw is List<int>) return jsonDecode(utf8.decode(raw));
    return raw;
  }

  void dispose() {
    _teardownChannel();
    _appointmentEventsCtrl.close();
    _availabilityEventsCtrl.close();
    _connectedCtrl.close();
    _disconnectedCtrl.close();
  }
}
