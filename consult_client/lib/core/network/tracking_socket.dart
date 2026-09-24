import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class DriverLocationUpdate {
  final String bookingId;
  final double lat;
  final double lng;

  const DriverLocationUpdate({
    required this.bookingId,
    required this.lat,
    required this.lng,
  });
}

/// Live driver-position feed backed by the API's `/ws/tracking` endpoint.
///
/// The JWT is sent as the first frame rather than a query parameter so it never
/// lands in proxy or access logs.
class TrackingSocket {
  TrackingSocket._();
  static final TrackingSocket instance = TrackingSocket._();

  static const Duration _maxBackoff = Duration(seconds: 30);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _disposed = false;
  bool _authenticated = false;

  final Set<String> _desiredBookingIds = {};
  final _updates = StreamController<DriverLocationUpdate>.broadcast();

  Stream<DriverLocationUpdate> get updates => _updates.stream;
  bool get isConnected => _authenticated;

  void connect() {
    if (_disposed || _channel != null) return;

    final token = ApiClient.instance.token;
    if (token == null || token.isEmpty) return;

    final uri = Uri.parse('${AppConstants.wsBaseUrl}/ws/tracking');

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      _subscription = channel.stream.listen(
        _onMessage,
        onError: (Object err) {
          debugPrint('TrackingSocket error: $err');
          _scheduleReconnect();
        },
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );

      _send({'type': 'auth', 'token': token});
    } catch (e) {
      debugPrint('TrackingSocket connect failed: $e');
      _scheduleReconnect();
    }
  }

  void subscribeTo(Iterable<String> bookingIds) {
    final added = bookingIds.toSet().difference(_desiredBookingIds);
    _desiredBookingIds.addAll(added);

    if (_authenticated) {
      for (final id in added) {
        _send({'type': 'subscribe', 'bookingId': id});
      }
    } else {
      // The provider is built before login, so the first connect attempt can
      // happen with no token. Retry here, once a fetch proves we're signed in.
      connect();
    }
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (msg['type']) {
      case 'auth_ok':
        _authenticated = true;
        _attempt = 0;
        for (final id in _desiredBookingIds) {
          _send({'type': 'subscribe', 'bookingId': id});
        }
        break;

      case 'auth_error':
        // A rejected token won't fix itself by retrying with the same token.
        debugPrint('TrackingSocket auth rejected: ${msg['error']}');
        _authenticated = false;
        _teardown();
        break;

      case 'driver_location':
        final lat = (msg['lat'] as num?)?.toDouble();
        final lng = (msg['lng'] as num?)?.toDouble();
        final bookingId = msg['bookingId'] as String?;
        if (lat != null && lng != null && bookingId != null) {
          _updates.add(
            DriverLocationUpdate(bookingId: bookingId, lat: lat, lng: lng),
          );
        }
        break;

      case 'error':
        debugPrint('TrackingSocket server error: ${msg['error']}');
        break;
    }
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('TrackingSocket send failed: $e');
    }
  }

  void _teardown() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _authenticated = false;
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _teardown();

    _attempt++;
    final backoffSeconds = (1 << (_attempt - 1)).clamp(1, _maxBackoff.inSeconds);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), connect);
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _teardown();
    _updates.close();
  }
}
