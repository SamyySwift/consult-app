import 'dart:math';
import '../network/api_client.dart';

/// A place with known coordinates, ready to use as a pickup or delivery point.
class PlaceResult {
  final String name;
  final String? details;
  final double lat;
  final double lng;

  const PlaceResult({
    required this.name,
    this.details,
    required this.lat,
    required this.lng,
  });

  /// Single-line address used for the booking.
  String get fullAddress => details == null ? name : '$name, $details';
}

/// An address suggestion from search. It has no coordinates yet: pass it to
/// [GeocodingService.resolve] once the user picks it.
class PlaceSuggestion {
  final String placeId;
  final String name;
  final String? details;

  const PlaceSuggestion({required this.placeId, required this.name, this.details});
}

/// Address search and reverse geocoding through our backend, which calls
/// Google Places (New) and the Geocoding API with a server-only key.
///
/// Google bills a search session (every suggestion request plus the one place
/// the user picks) as a single lookup, so callers keep one [newSessionToken]
/// per search and pass it to both [search] and [resolve].
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  final _random = Random.secure();

  /// A random UUID v4, the format Google expects for session tokens.
  String newSessionToken() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Suggestions for [query], or null when search is unavailable (network or
  /// Google error), which callers show differently from "no matches".
  Future<List<PlaceSuggestion>?> search(String query, {required String sessionToken}) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    final res = await ApiClient.instance.get(
      '/api/maps/autocomplete?q=${Uri.encodeQueryComponent(q)}'
      '&session=${Uri.encodeQueryComponent(sessionToken)}',
    );
    if (!res.isSuccess || res.data is! List) return null;

    return [
      for (final s in res.data as List)
        if (s is Map && s['placeId'] is String && s['name'] is String)
          PlaceSuggestion(
            placeId: s['placeId'] as String,
            name: s['name'] as String,
            details: s['details'] as String?,
          ),
    ];
  }

  /// Coordinates for a picked suggestion, or null if it couldn't be loaded.
  Future<PlaceResult?> resolve(PlaceSuggestion suggestion, {required String sessionToken}) async {
    final res = await ApiClient.instance.get(
      '/api/maps/place/${Uri.encodeComponent(suggestion.placeId)}'
      '?session=${Uri.encodeQueryComponent(sessionToken)}',
    );
    final data = res.data;
    if (!res.isSuccess || data is! Map || data['lat'] is! num || data['lng'] is! num) return null;

    return PlaceResult(
      name: suggestion.name,
      details: suggestion.details,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
    );
  }

  /// The address at a map point, or null if there isn't one or lookup failed.
  Future<PlaceResult?> reverse(double lat, double lng) async {
    final res = await ApiClient.instance.get('/api/maps/reverse?lat=$lat&lng=$lng');
    final data = res.data;
    if (!res.isSuccess || data is! Map || data['name'] is! String) return null;

    return PlaceResult(
      name: data['name'] as String,
      details: data['details'] as String?,
      // The pin's exact position; the backend echoes it back
      lat: (data['lat'] as num?)?.toDouble() ?? lat,
      lng: (data['lng'] as num?)?.toDouble() ?? lng,
    );
  }
}
