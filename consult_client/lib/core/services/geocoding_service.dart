import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

/// Address search and reverse geocoding via Photon (OpenStreetMap data, no API key).
/// Photon is built for search-as-you-type, unlike Nominatim whose policy forbids it.
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const _baseUrl = 'https://photon.komoot.io';
  // minLon,minLat,maxLon,maxLat — keeps results inside Nigeria
  static const _nigeriaBbox = '2.67,4.27,14.68,13.89';
  static const _timeout = Duration(seconds: 8);

  Future<List<PlaceResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final uri = Uri.parse('$_baseUrl/api/').replace(queryParameters: {
      'q': q,
      'limit': '8',
      'lang': 'en',
      'bbox': _nigeriaBbox,
    });

    final results = await _fetch(uri);
    // OSM often splits one road into several segments with the same name
    final seen = <String>{};
    return results.where((r) => seen.add(r.fullAddress)).take(5).toList();
  }

  Future<PlaceResult?> reverse(double lat, double lng) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
      'lat': '$lat',
      'lon': '$lng',
      'lang': 'en',
    });
    final results = await _fetch(uri);
    return results.isEmpty ? null : results.first;
  }

  Future<List<PlaceResult>> _fetch(Uri uri) async {
    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return [];

      final features = (jsonDecode(res.body)['features'] as List?) ?? [];
      return features.map(_parseFeature).whereType<PlaceResult>().toList();
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return [];
    }
  }

  PlaceResult? _parseFeature(dynamic feature) {
    final coords = feature['geometry']?['coordinates'] as List?;
    final props = feature['properties'] as Map<String, dynamic>?;
    if (coords == null || coords.length < 2 || props == null) return null;

    String? str(String key) {
      final v = props[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final street = [str('housenumber'), str('street')].whereType<String>().join(' ');
    final name = str('name') ?? (street.isNotEmpty ? street : null);
    if (name == null) return null;

    // Skip parts that repeat the name (e.g. a city result whose city is itself)
    final detailParts = <String>[];
    for (final part in [
      if (str('name') != null && street.isNotEmpty) street,
      str('district'),
      str('city'),
      str('state'),
    ]) {
      if (part != null && part != name && !detailParts.contains(part)) {
        detailParts.add(part);
      }
    }

    return PlaceResult(
      name: name,
      details: detailParts.isEmpty ? null : detailParts.join(', '),
      lat: (coords[1] as num).toDouble(),
      lng: (coords[0] as num).toDouble(),
    );
  }
}
