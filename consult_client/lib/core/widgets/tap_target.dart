import 'package:flutter/material.dart';

/// Gives a small visual control (a text link, a compact pill) a hit region of
/// at least 44x44 pt, the iOS default, without changing how it looks.
class TapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const TapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });

  static const double minSize = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
