import 'package:flutter/material.dart';
import '../theme/driver_colors.dart';

/// Flat card for the content layer: solid surface with a hairline border.
///
/// Glass belongs to floating controls (tab bar, header buttons, sheets); cards,
/// rows and tiles that scroll with content use this instead. [borderColor]
/// highlights a selected or status-bearing card without a glow.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.width,
    this.height,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DriverColors.surface,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? DriverColors.border),
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(borderRadius: shape, onTap: onTap, child: content),
            ),
    );
  }
}

/// Flat rounded square holding an icon, for the leading slot of a card or row.
/// [tint] colours it for status (green active, amber waiting, red problem);
/// leave it null for a neutral tile.
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final Color? tint;

  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 20,
    this.radius = 14,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final tint = this.tint;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint != null
            ? tint.withValues(alpha: 0.12)
            : DriverColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: tint == null
            ? Colors.white.withValues(alpha: 0.85)
            : tint == DriverColors.accent
            ? DriverColors.accentLight
            : tint,
      ),
    );
  }
}

/// Small flat label chip, e.g. a service name or "KYC STEP".
class FlatChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const FlatChip({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    final fg = color == null
        ? Colors.white.withValues(alpha: 0.8)
        : color == DriverColors.accent
        ? DriverColors.accentLight
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color != null
            ? color.withValues(alpha: 0.12)
            : DriverColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
