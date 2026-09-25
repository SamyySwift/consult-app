import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// True when the person has turned on Reduce Motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

extension MotionAwareAnimate on Widget {
  /// Drop-in for flutter_animate's `.animate()`: with Reduce Motion on, the
  /// effects chained after it render at their end state and never play.
  Animate motionAware(BuildContext context, {Duration? delay}) =>
      reduceMotion(context)
      ? animate(value: 1, autoPlay: false)
      : animate(delay: delay);
}

extension EntranceAnimation on Widget {
  /// Fades (and optionally slides) this widget in, unless Reduce Motion is on,
  /// in which case it appears immediately.
  Widget entrance(
    BuildContext context, {
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
    double slide = 0.08,
  }) {
    if (reduceMotion(context)) return this;
    final faded = animate(delay: delay).fadeIn(duration: duration);
    return slide == 0 ? faded : faded.slideY(begin: slide);
  }
}
