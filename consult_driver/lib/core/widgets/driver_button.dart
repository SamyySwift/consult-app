import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/driver_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? DriverColors.accent,
          side: BorderSide(color: foregroundColor ?? DriverColors.accent, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _child(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: backgroundColor == null
            ? DriverColors.accentGradient
            : null,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? DriverColors.accent).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _child(),
      ),
    );
  }

  Widget _child() {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: foregroundColor ?? Colors.black, strokeWidth: 2.5),
      );
    }
    final textStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: foregroundColor ?? (isOutlined ? DriverColors.accent : Colors.black),
    );
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(label, style: textStyle),
        ],
      );
    }
    return Text(label, style: textStyle);
  }
}
