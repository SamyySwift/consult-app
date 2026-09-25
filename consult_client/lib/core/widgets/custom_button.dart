import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 54,
    this.borderRadius = 14,
  });

  const CustomButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 54,
    this.borderRadius = 14,
  }) : isOutlined = true;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (isOutlined ? Colors.transparent : context.colors.accent);
    final fg = foregroundColor ?? (isOutlined ? context.colors.accent : Colors.black);

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isOutlined ? context.colors.accent : Colors.black,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, SizedBox(width: 8)],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: isOutlined ? BorderSide(color: context.colors.border, width: 1.5) : BorderSide.none,
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                side: BorderSide(color: context.colors.border, width: 1.5),
                shape: shape,
                padding: EdgeInsets.zero,
              ),
              child: child,
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: onPressed != null && !isLoading ? context.colors.accentGradient : null,
                color: onPressed == null || isLoading ? context.colors.border : null,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: onPressed != null && !isLoading
                    ? [
                        BoxShadow(
                          color: context.colors.accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
                  padding: EdgeInsets.zero,
                  minimumSize: Size(width ?? double.infinity, height),
                ),
                child: child,
              ),
            ),
    );
  }
}
