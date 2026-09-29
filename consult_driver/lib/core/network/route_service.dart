import 'package:google_navigation_flutter/google_navigation_flutter.dart' show LatLng;
import 'api_client.dart';

/// A driving route that follows the road network.
class RoadRoute {
  final List<LatLng> points;
  final double distanceM;
  final double durationS;

  const RoadRoute({
    required this.points,
    required this.distanceM,
    required this.durationS,
  });
}

/// Fetches road routes from the backend (which proxies and caches Google
/// Routes). Used for the job overview before navigation starts; turn-by-turn
/// guidance calculates its own route. Returns null when routing is
/// unavailable, so callers can fall back to straight lines.
class RouteService {
  RouteService._();
  static final RouteService instance = RouteService._();

  final _cache = <String, RoadRoute>{};

  Future<RoadRoute?> fetch(LatLng from, LatLng to) async {
    String point(LatLng p) =>
        '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
    final key = '${point(from)};${point(to)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final res = await ApiClient.instance.get(
        '/api/maps/route?from=${point(from)}&to=${point(to)}',
      );
      final data = res.data;
      if (!res.isSuccess || data is! Map) return null;

      final route = RoadRoute(
        points: [
          for (final c in data['coordinates'] as List)
            LatLng(latitude: (c[0] as num).toDouble(), longitude: (c[1] as num).toDouble()),
        ],
        distanceM: (data['distance_m'] as num).toDouble(),
        durationS: (data['duration_s'] as num).toDouble(),
      );
      if (route.points.length < 2) return null;
      return _cache[key] = route;
    } catch (_) {
      return null;
    }
  }
}
