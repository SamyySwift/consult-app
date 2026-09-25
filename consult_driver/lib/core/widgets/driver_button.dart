import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/driver_colors.dart';
import 'glass.dart';

/// The app's button. Primary buttons are the glowing glass pill, outlined
/// ones a plain glass pill, and a custom [backgroundColor] (other than the
/// accent) gives a solid pill in that colour.
class DriverButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const DriverButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  const DriverButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  }) : isOutlined = true;

  static const double _height = 58;

  @override
  Widget build(BuildContext context) {
    final solid = backgroundColor != null && backgroundColor != DriverColors.accent && !isOutlined;

    if (!isOutlined && !solid) {
      return GlowButton(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        icon: icon,
      );
    }

    final fg = foregroundColor ?? (isOutlined ? DriverColors.accent : Colors.white);
    final Widget pill = solid
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: backgroundColor!.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6)),
              ],
            ),
            child: SizedBox(height: _height, width: double.infinity, child: Center(child: _content(fg))),
          )
        : GlassContainer(
            radius: 999,
            tint: fg,
            child: SizedBox(height: _height, width: double.infinity, child: Center(child: _content(fg))),
          );

    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onPressed == null && !isLoading ? 0.5 : 1,
          child: pill,
        ),
      ),
    );
  }

  Widget _content(Color fg) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: fg, strokeWidth: 2.5),
      );
    }
    final text = Text(
      label,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [icon!, const SizedBox(width: 8), text],
    );
  }
}
