import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Straight-line distance between two points, in metres.
double metersBetween(LatLng a, LatLng b) =>
    Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);

/// Dark Google Maps style for the full-screen tracking maps.
const String darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0e0f0f"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8f8d"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0e0f0f"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2a2d2c"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#262928"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#161817"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#34383a"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0b5b3"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#07090b"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4a4f4d"}]}
]
''';

/// Moves the camera so every point is on screen, [edge] logical pixels inside
/// the map's padding, without zooming in past [maxZoom].
Future<void> fitPoints(
  GoogleMapController controller,
  Iterable<LatLng> points, {
  double edge = 40,
  double maxZoom = 15,
  bool animate = true,
}) async {
  if (points.isEmpty) return;
  var south = 90.0, north = -90.0, west = 180.0, east = -180.0;
  for (final p in points) {
    south = math.min(south, p.latitude);
    north = math.max(north, p.latitude);
    west = math.min(west, p.longitude);
    east = math.max(east, p.longitude);
  }

  // Fitting a tiny box would zoom to street level, so centre on it instead
  final tiny = north - south < 0.005 && east - west < 0.005;
  final update = tiny
      ? CameraUpdate.newLatLngZoom(LatLng((south + north) / 2, (west + east) / 2), maxZoom)
      : CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
          edge,
        );
  try {
    await (animate ? controller.animateCamera(update) : controller.moveCamera(update));
  } catch (_) {
    // Android rejects bounds fits before the map has a size; the initial
    // camera stays in place and the next fit corrects it.
  }
}

/// Round map markers drawn to bitmaps, since Google Maps markers are images
/// rather than widgets. Results are cached per look.
class MarkerIcons {
  MarkerIcons._();

  static final _cache = <String, Future<BitmapDescriptor>>{};

  /// A disc of [size] filled with [color] or [gradient], with an optional
  /// [border], a centred [icon], a soft [glow] behind it and a translucent
  /// [halo] disc of [haloSize] around it.
  static Future<BitmapDescriptor> circle({
    required double size,
    required double pixelRatio,
    Color? color,
    Gradient? gradient,
    Color? borderColor,
    double borderWidth = 0,
    IconData? icon,
    Color iconColor = Colors.white,
    double iconSize = 0,
    Color? glow,
    double glowBlur = 0,
    Color? halo,
    double haloSize = 0,
  }) {
    final key = [
      size, pixelRatio, color, gradient, borderColor, borderWidth, icon?.codePoint,
      iconColor, iconSize, glow, glowBlur, halo, haloSize,
    ].join('|');
    return _cache[key] ??= _draw(
      size: size,
      pixelRatio: pixelRatio,
      color: color,
      gradient: gradient,
      borderColor: borderColor,
      borderWidth: borderWidth,
      icon: icon,
      iconColor: iconColor,
      iconSize: iconSize,
      glow: glow,
      glowBlur: glowBlur,
      halo: halo,
      haloSize: haloSize,
    );
  }

  static Future<BitmapDescriptor> _draw({
    required double size,
    required double pixelRatio,
    Color? color,
    Gradient? gradient,
    Color? borderColor,
    required double borderWidth,
    IconData? icon,
    required Color iconColor,
    required double iconSize,
    Color? glow,
    required double glowBlur,
    Color? halo,
    required double haloSize,
  }) async {
    // Room for the glow on every side keeps the disc centred on the anchor
    final extent = math.max(size, haloSize) + glowBlur * 2;
    final center = Offset(extent / 2, extent / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);

    if (halo != null) canvas.drawCircle(center, haloSize / 2, Paint()..color = halo);
    if (glow != null) {
      canvas.drawCircle(
        center,
        size / 2,
        Paint()
          ..color = glow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(glowBlur)),
      );
    }

    final fill = Paint()..color = color ?? Colors.transparent;
    if (gradient != null) {
      fill.shader = gradient.createShader(Rect.fromCircle(center: center, radius: size / 2));
    }
    canvas.drawCircle(center, size / 2, fill);

    if (borderColor != null && borderWidth > 0) {
      canvas.drawCircle(
        center,
        (size - borderWidth) / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = borderColor,
      );
    }

    if (icon != null) {
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: iconSize,
            color: iconColor,
          ),
        ),
      )..layout();
      painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
    }

    final px = (extent * pixelRatio).ceil();
    final image = await recorder.endRecording().toImage(px, px);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: pixelRatio);
  }
}
