import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/map_utils.dart';
import 'api_client.dart';

/// A driving route that follows the road network.
class RoadRoute {
  final List<LatLng> points;
  final double distanceM;
  final double durationS;

  /// Distance along the road from the start to each point, in metres.
  late final List<double> _cumulativeM = _accumulate(points);

  RoadRoute({
    required this.points,
    required this.distanceM,
    required this.durationS,
  });

  static List<double> _accumulate(List<LatLng> points) {
    final out = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      out[i] = out[i - 1] + metersBetween(points[i - 1], points[i]);
    }
    return out;
  }

  /// Index of the route point closest to [p].
  int nearestIndex(LatLng p) {
    // Squared equirectangular distance: accurate enough to pick the nearest
    // point and far cheaper than haversine over thousands of points.
    final cosLat = math.cos(p.latitude * math.pi / 180);
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final dLat = points[i].latitude - p.latitude;
      final dLng = (points[i].longitude - p.longitude) * cosLat;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// Road distance left from the point at [index] to the end, in metres.
  double remainingFromM(int index) => _cumulativeM.last - _cumulativeM[index];
}

/// Fetches road routes from the backend (which proxies and caches Mapbox
/// Directions). Returns null when routing is unavailable, so callers can fall
/// back to straight lines.
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
            LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()),
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
