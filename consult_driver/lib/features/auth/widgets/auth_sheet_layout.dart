import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/motion.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/glass.dart';

/// Auth screen shell: the car-carrier photo on top, and a dark sheet with a
/// domed top edge holding [child].
///
/// When the keyboard opens the sheet shrinks to fit its content and pushes
/// the photo up with it, so the form stays visible.
class AuthSheetLayout extends StatelessWidget {
  /// Height of the sheet as a fraction of the screen, with the keyboard closed.
  final double sheetHeight;

  /// Back action; no back button (and normal system back) when null.
  final VoidCallback? onBack;
  final Widget child;

  const AuthSheetLayout({
    super.key,
    required this.sheetHeight,
    this.onBack,
    required this.child,
  });

  static const double curveHeight = 70;

  // How far the photo extends under the sheet, as a fraction of the screen.
  static const double _heroOverlap = 0.17;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bodyHeight = screen.height - keyboard;
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = 1 - sheetHeight + _heroOverlap;

    final onBack = this.onBack;

    // The system back gesture/button does the same as the on-screen one.
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Stack(
          children: [
            Column(
              children: [
                // Hero image, anchored to the top of the sheet so it slides
                // up with the form when the keyboard opens.
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -screen.height * _heroOverlap,
                        height: screen.height * heroHeight,
                        child: Image.network(
                          AppConstants.heroImageUrl,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.15, 0),
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sheet with a curved top edge. It keeps its full height until
                // the keyboard eats into the empty space below the form, then
                // pushes the hero up.
                ClipPath(
                  clipper: _CurvedTopClipper(curveHeight: curveHeight),
                  child: Container(
                    color: context.colors.surface,
                    constraints: BoxConstraints(
                      minHeight: (screen.height * sheetHeight - keyboard).clamp(
                        0,
                        double.infinity,
                      ),
                      maxHeight: bodyHeight - topInset,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        curveHeight + 12,
                        24,
                        32,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
            if (onBack != null)
              Positioned(
                top: topInset + 16,
                left: 20,
                child: GlassIconButton(
                  icon: Icons.chevron_left_rounded,
                  semanticLabel: 'Back',
                  onTap: onBack,
                ),
              ).motionAware(context).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

/// Clips the top of the sheet into a dome: low at both sides, peaking in the
/// middle.
class _CurvedTopClipper extends CustomClipper<Path> {
  final double curveHeight;

  const _CurvedTopClipper({required this.curveHeight});

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, curveHeight)
      ..quadraticBezierTo(size.width / 2, -curveHeight, size.width, curveHeight)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_CurvedTopClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}
