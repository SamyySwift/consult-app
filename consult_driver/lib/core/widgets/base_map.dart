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
  // TomTom's 512px tile covers the same area as its 256px one at double
  // resolution, so it fills a standard 256pt slot: sharp on high-density
  // screens, with labels at their normal size.
  return TileLayer(
    urlTemplate:
        'https://api.tomtom.com/maps/orbis/display/raster/tile/{z}/{x}/{y}'
        '?apiVersion=2&style={style}&tileSize=512&key={key}',
    additionalOptions: {'style': dark ? 'street-dark' : 'street-light', 'key': key},
    userAgentPackageName: _userAgent,
  );
}

/// Credit line the tile provider requires on every map.
String get mapAttribution =>
    AppConstants.tomtomApiKey != null ? '© TomTom' : '© OpenStreetMap';
