import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Round map markers drawn to bitmaps and registered with the Navigation SDK,
/// since its markers are images rather than widgets. Cached per look.
class MarkerImages {
  MarkerImages._();

  static final _cache = <String, Future<ImageDescriptor>>{};

  /// A disc of [size] filled with [color] or [gradient], with an optional
  /// [borderColor], a centred [icon], a soft [glow] behind it and a
  /// translucent [halo] disc of [haloSize] around it.
  static Future<ImageDescriptor> circle({
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

  static Future<ImageDescriptor> _draw({
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
    return registerBitmapImage(bitmap: bytes!, imagePixelRatio: pixelRatio);
  }
}
