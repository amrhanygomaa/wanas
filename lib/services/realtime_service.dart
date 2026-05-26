import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import 'auth_service.dart';

class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  final StreamController<Map<String, dynamic>> _liveEvents =
      StreamController<Map<String, dynamic>>.broadcast();

  io.Socket? _socket;
  String? _facilityId;
  String? _userId;

  Stream<Map<String, dynamic>> get liveEvents {
    connect();
    return _liveEvents.stream;
  }

  Stream<Map<String, dynamic>> liveEventsFor(Set<String> types) {
    return liveEvents.where((event) {
      final type = event['type']?.toString();
      return type != null && types.contains(type);
    });
  }

  void connect() {
    final user = AuthService.instance.currentUser;
    if (user == null || user.facilityId.isEmpty) return;

    if (_socket != null &&
        _facilityId == user.facilityId &&
        _userId == user.userId) {
      if (_socket?.connected != true) _socket?.connect();
      return;
    }

    disconnect();
    _facilityId = user.facilityId;
    _userId = user.userId;

    final base = Uri.parse(ApiConfig.baseUrl);
    final endpoint = '${base.scheme}://${base.authority}/realtime';

    final socket = io.io(
      endpoint,
      io.OptionBuilder()
          .setTransports(['polling'])
          .disableAutoConnect()
          .setQuery({
            'facilityId': user.facilityId,
            'userId': user.userId,
          })
          .build(),
    );

    socket.onConnect((_) {
      if (kDebugMode) {
        debugPrint('[Realtime] connected ${user.facilityId}/${user.userId}');
      }
    });
    socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('[Realtime] disconnected');
    });
    socket.onError((error) {
      if (kDebugMode) debugPrint('[Realtime] error: $error');
    });
    socket.onConnectError((error) {
      if (kDebugMode) debugPrint('[Realtime] connect error: $error');
    });

    socket.on('live_event', _emit);
    socket.on('notification', (data) {
      _emit({'type': 'notifications', 'action': 'notification', 'data': data});
    });
    socket.on('message', (data) {
      _emit({'type': 'messages', 'action': 'message', 'data': data});
    });
    socket.on('vitals_updated', (data) {
      _emit({'type': 'health', 'action': 'vitals_updated', 'data': data});
    });
    socket.on('sos_alert', (data) {
      _emit({'type': 'health', 'action': 'sos_alert', 'data': data});
    });

    _socket = socket;
    socket.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _facilityId = null;
    _userId = null;
  }

  void _emit(dynamic data) {
    final event = _asStringKeyedMap(data);
    if (event == null || _liveEvents.isClosed) return;
    _liveEvents.add(event);
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data == null) return null;
    return {'type': 'unknown', 'action': 'event', 'data': data};
  }
}
