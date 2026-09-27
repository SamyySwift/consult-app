import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

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

/// Address search and reverse geocoding via TomTom Search when
/// `TOMTOM_API_KEY` is set, otherwise via Photon (OpenStreetMap data, no key).
/// Photon is built for search-as-you-type, unlike Nominatim whose policy forbids it.
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const _photonUrl = 'https://photon.komoot.io';
  // minLon,minLat,maxLon,maxLat — keeps results inside Nigeria
  static const _nigeriaBbox = '2.67,4.27,14.68,13.89';
  static const _timeout = Duration(seconds: 8);

  Future<List<PlaceResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final key = AppConstants.tomtomApiKey;
    final results = key != null
        ? await _fetch(
            _tomtomUri(['search', '$q.json'], key, {
              'typeahead': 'true',
              'countrySet': 'NG',
              'limit': '8',
            }),
            'results',
            _parseTomTom,
          )
        : await _fetch(
            Uri.parse('$_photonUrl/api/').replace(queryParameters: {
              'q': q,
              'limit': '8',
              'lang': 'en',
              'bbox': _nigeriaBbox,
            }),
            'features',
            _parsePhoton,
          );

    // Road data often splits one road into several segments with the same name
    final seen = <String>{};
    return results.where((r) => seen.add(r.fullAddress)).take(5).toList();
  }

  Future<PlaceResult?> reverse(double lat, double lng) async {
    final key = AppConstants.tomtomApiKey;
    final results = key != null
        ? await _fetch(
            _tomtomUri(['reverseGeocode', '$lat,$lng.json'], key, {}),
            'addresses',
            _parseTomTom,
          )
        : await _fetch(
            Uri.parse('$_photonUrl/reverse').replace(queryParameters: {
              'lat': '$lat',
              'lon': '$lng',
              'lang': 'en',
            }),
            'features',
            _parsePhoton,
          );
    return results.isEmpty ? null : results.first;
  }

  /// A TomTom Search API URL. Path segments are encoded individually, so a
  /// `/` typed into a query stays part of the query.
  Uri _tomtomUri(List<String> path, String key, Map<String, String> params) => Uri(
        scheme: 'https',
        host: 'api.tomtom.com',
        pathSegments: ['search', '2', ...path],
        queryParameters: {...params, 'language': 'en-GB', 'key': key},
      );

  /// Fetches [uri] and parses each entry of the response's [listKey] array.
  Future<List<PlaceResult>> _fetch(
    Uri uri,
    String listKey,
    PlaceResult? Function(dynamic) parse,
  ) async {
    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('Geocoding failed: HTTP ${res.statusCode} from ${uri.host}');
        return [];
      }

      final items = (jsonDecode(res.body)[listKey] as List?) ?? [];
      return items.map(parse).whereType<PlaceResult>().toList();
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return [];
    }
  }

  PlaceResult? _parsePhoton(dynamic feature) {
    final coords = feature['geometry']?['coordinates'] as List?;
    final props = feature['properties'] as Map<String, dynamic>?;
    if (coords == null || coords.length < 2 || props == null) return null;

    String? str(String key) => _clean(props[key]);

    final street = [str('housenumber'), str('street')].whereType<String>().join(' ');
    final name = str('name') ?? (street.isNotEmpty ? street : null);
    if (name == null) return null;

    return _place(
      name,
      [
        if (str('name') != null && street.isNotEmpty) street,
        str('district'),
        str('city'),
        str('state'),
      ],
      (coords[1] as num).toDouble(),
      (coords[0] as num).toDouble(),
    );
  }

  PlaceResult? _parseTomTom(dynamic result) {
    final address = result['address'] as Map<String, dynamic>?;
    final position = result['position'];
    if (address == null || position == null) return null;

    // Search returns {lat, lon}; reverse geocoding returns a "lat,lon" string
    final double lat;
    final double lng;
    if (position is Map) {
      lat = (position['lat'] as num).toDouble();
      lng = (position['lon'] as num).toDouble();
    } else {
      final parts = '$position'.split(',');
      if (parts.length != 2) return null;
      lat = double.parse(parts[0]);
      lng = double.parse(parts[1]);
    }

    String? str(String key) => _clean(address[key]);

    final poi = _clean(result['poi']?['name']);
    final street = [str('streetNumber'), str('streetName')].whereType<String>().join(' ');
    final name = poi ?? (street.isNotEmpty ? street : null) ?? str('freeformAddress');
    if (name == null) return null;

    return _place(
      name,
      [
        if (poi != null && street.isNotEmpty) street,
        str('municipalitySubdivision'),
        str('municipality'),
        str('countrySubdivision'),
      ],
      lat,
      lng,
    );
  }

  static String? _clean(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  static PlaceResult _place(String name, List<String?> parts, double lat, double lng) {
    // Skip parts that repeat the name (e.g. a city result whose city is itself)
    final detailParts = <String>[];
    for (final part in parts) {
      if (part != null && part != name && !detailParts.contains(part)) {
        detailParts.add(part);
      }
    }
    return PlaceResult(
      name: name,
      details: detailParts.isEmpty ? null : detailParts.join(', '),
      lat: lat,
      lng: lng,
    );
  }
}
