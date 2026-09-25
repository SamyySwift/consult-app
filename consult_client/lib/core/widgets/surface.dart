import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Flat card for the content layer: solid surface with a hairline border.
///
/// Glass belongs to floating controls (tab bar, header buttons, sheets); cards,
/// rows and tiles that scroll with content use this instead.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.width,
    this.height,
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
        color: context.colors.surface,
        borderRadius: shape,
        border: Border.all(color: context.colors.border),
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
/// [accent] tints it green; keep that for tiles that carry status.
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final bool accent;

  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 20,
    this.radius = 14,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent
            ? colors.accent.withValues(alpha: 0.12)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: accent
            ? colors.accentLight
            : Colors.white.withValues(alpha: 0.85),
      ),
    );
  }
}

/// Small flat label chip, e.g. a service name or "LIMITED OFFER".
class FlatChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool accent;

  const FlatChip({
    super.key,
    required this.label,
    this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = accent
        ? colors.accentLight
        : Colors.white.withValues(alpha: 0.8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? colors.accent.withValues(alpha: 0.12)
            : colors.surfaceVariant,
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
