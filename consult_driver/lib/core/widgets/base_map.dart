import 'package:flutter_map/flutter_map.dart';
import '../constants/app_constants.dart';

const _userAgent = 'com.carpitalconsult.driver';

/// Base map tiles: TomTom when `TOMTOM_API_KEY` is set, otherwise OpenStreetMap
/// so the maps still work without a key.
TileLayer baseMapTiles({required bool dark}) {
  final key = AppConstants.tomtomApiKey;
  if (key == null) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: _userAgent,
    );
  }
  return TileLayer(
    urlTemplate:
        'https://api.tomtom.com/maps/orbis/display/raster/tile/{z}/{x}/{y}'
        '?apiVersion=2&style={style}&tileSize=512&key={key}',
    additionalOptions: {'style': dark ? 'street-dark' : 'street-light', 'key': key},
    tileSize: 512,
    zoomOffset: -1,
    userAgentPackageName: _userAgent,
  );
}

/// Credit line the tile provider requires on every map.
String get mapAttribution =>
    AppConstants.tomtomApiKey != null ? '© TomTom' : '© OpenStreetMap';
