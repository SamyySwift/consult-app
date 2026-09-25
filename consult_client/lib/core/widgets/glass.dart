import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Frosted-glass surface: a faint white fill, a light gradient rim and,
/// optionally, a real backdrop blur and an accent glow.
///
/// Only enable [blur] on surfaces that sit over imagery — over plain black it
/// is invisible and costs a render pass per widget.
///
/// With [progress] set (0–1) the rim becomes a dim track with a bright accent
/// segment running clockwise from top-centre, like a progress ring.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool blur;
  final bool glow;
  final Color? tint;
  final double? progress;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.width,
    this.height,
    this.blur = false,
    this.glow = false,
    this.tint,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final fill = tint ?? Colors.white;

    Widget body = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill.withValues(alpha: 0.10), fill.withValues(alpha: 0.03)],
        ),
      ),
      child: child,
    );

    if (blur) {
      body = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: body,
        ),
      );
    }

    // The rim is painted outside the clip so the glow can bleed past the edge.
    return CustomPaint(
      foregroundPainter: _RimPainter(
        radius: radius,
        glow: glow,
        progress: progress?.clamp(0.0, 1.0),
        accent: context.colors.accent,
        accentLight: context.colors.accentLight,
      ),
      child: body,
    );
  }
}

/// Stadium-shaped [GlassContainer] for chips and small buttons.
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool blur;
  final bool glow;
  final Color? tint;
  final double? progress;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.blur = false,
    this.glow = false,
    this.tint,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 999,
      padding: padding,
      blur: blur,
      glow: glow,
      tint: tint,
      progress: progress,
      child: child,
    );
  }
}

/// Rounded-rect outline starting at top-centre and running clockwise, so a
/// progress segment can be cut from its start.
Path _rimPath(Rect rect, double radius) {
  final r = math.min(radius, rect.shortestSide / 2);
  final corner = Radius.circular(r);
  return Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right - r, rect.top)
    ..arcToPoint(Offset(rect.right, rect.top + r), radius: corner)
    ..lineTo(rect.right, rect.bottom - r)
    ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: corner)
    ..lineTo(rect.left + r, rect.bottom)
    ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: corner)
    ..lineTo(rect.left, rect.top + r)
    ..arcToPoint(Offset(rect.left + r, rect.top), radius: corner)
    ..close();
}

class _RimPainter extends CustomPainter {
  final double radius;
  final bool glow;
  final double? progress;
  final Color accent;
  final Color accentLight;

  _RimPainter({
    required this.radius,
    required this.glow,
    required this.progress,
    required this.accent,
    required this.accentLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final progress = this.progress;

    if (progress != null) {
      _paintProgress(canvas, rect, progress);
      return;
    }

    final path = _rimPath(rect.deflate(0.5), radius);

    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = accentLight.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    final rimColors = glow
        ? [
            accentLight.withValues(alpha: 0.90),
            accent.withValues(alpha: 0.20),
            accentLight.withValues(alpha: 0.65),
          ]
        : [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.14),
          ];

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow ? 1.4 : 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rimColors,
        ).createShader(rect),
    );
  }

  void _paintProgress(Canvas canvas, Rect rect, double progress) {
    const stroke = 2.5;
    final path = _rimPath(rect.deflate(stroke / 2), radius);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    if (progress <= 0) return;

    final metric = path.computeMetrics().first;
    final segment = metric.extractPath(0, metric.length * progress);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accentLight, accent],
    ).createShader(rect);

    canvas.drawPath(
      segment,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 3
        ..strokeCap = StrokeCap.round
        ..color = accentLight.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      segment,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.radius != radius ||
      old.glow != glow ||
      old.progress != progress ||
      old.accent != accent ||
      old.accentLight != accentLight;
}

// ── Page scaffolding ──────────────────────────────────────────────────────

/// Pure black with a dark green glow across the top of the screen.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final accent = context.colors.accent;

    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Colors.black)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.45,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.5, 1],
                colors: [Color(0xFF12301F), Color(0xFF07140D), Colors.black],
              ),
            ),
          ),
        ),
        Positioned(
          top: -size.height * 0.15,
          left: -size.width * 0.3,
          right: -size.width * 0.3,
          height: size.height * 0.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.14),
                  accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Blurred glass circle holding an icon, with an optional count badge.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final int badgeCount;
  final double size;
  final Color? iconColor;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.semanticLabel,
    this.badgeCount = 0,
    this.size = 46,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = GlassContainer(
      width: size,
      height: size,
      radius: size / 2,
      blur: true,
      child: Center(
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text(
            badgeCount > 99 ? '99+' : badgeCount.toString(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: context.colors.accent,
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: size * 0.46,
          ),
        ),
      ),
    );

    if (onTap == null) return button;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(onTap: onTap, child: button),
    );
  }
}

/// Screen header. Tab screens get a large left-aligned title; pushed screens
/// ([showBack]) get a glass back button with a centred title.
class GlassPageHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const GlassPageHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final spacedActions = [
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        actions[i],
      ],
    ];

    if (!showBack) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              ...spacedActions,
            ],
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            GlassIconButton(
              icon: Icons.chevron_left_rounded,
              semanticLabel: 'Back',
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            if (spacedActions.isEmpty)
              const SizedBox(width: 46)
            else
              ...spacedActions,
          ],
        ),
      ),
    );
  }
}

/// Glass pill split into equal segments, with a capsule that slides under
/// the selected one.
class GlassSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const GlassSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 999,
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / labels.length;
          return SizedBox(
            height: 38,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      SizedBox(
                        width: segmentWidth,
                        child: Semantics(
                          button: true,
                          selected: i == selectedIndex,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onChanged(i),
                            child: Center(
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: i == selectedIndex
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: i == selectedIndex
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Metrics ───────────────────────────────────────────────────────────────

/// Mint gradient used for hero numbers.
class GradientNumber extends StatelessWidget {
  final String text;
  final double fontSize;

  const GradientNumber(this.text, {super.key, this.fontSize = 80});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, context.colors.accentLight],
      ).createShader(rect),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
          letterSpacing: fontSize > 50 ? -2 : -1,
        ),
      ),
    );
  }
}

class StatPillData {
  final IconData icon;
  final String value;
  final String label;

  /// Share of the whole (0–1), drawn as a progress rim. Null for a plain
  /// glowing rim.
  final double? progress;

  const StatPillData({
    required this.icon,
    required this.value,
    required this.label,
    this.progress,
  });
}

/// Glowing glass pill with an icon and a value, labelled underneath.
class GlassStatPill extends StatelessWidget {
  final StatPillData data;
  const GlassStatPill(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scale down rather than overflow when a big count meets a narrow column.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: GlassPill(
            blur: true,
            glow: data.progress == null,
            progress: data.progress,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(data.icon, size: 18, color: context.colors.accentLight),
                const SizedBox(width: 6),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Opal-style hero: a label, a large gradient number, and a bracket fanning
/// out to a row of stat pills.
class BracketedStats extends StatelessWidget {
  final String label;
  final String value;
  final List<StatPillData> pills;

  const BracketedStats({
    super.key,
    required this.label,
    required this.value,
    required this.pills,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        FittedBox(fit: BoxFit.scaleDown, child: GradientNumber(value)),
        const SizedBox(height: 4),
        SizedBox(
          height: 30,
          width: double.infinity,
          child: CustomPaint(painter: _BracketPainter(count: pills.length)),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final pill in pills) Expanded(child: GlassStatPill(pill)),
          ],
        ),
      ],
    );
  }
}

/// Curly-bracket line from the hero number down to the centre of each of
/// [count] equal-width columns.
class _BracketPainter extends CustomPainter {
  final int count;
  _BracketPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final w = size.width;
    final h = size.height;
    final mid = h * 0.5;
    const r = 14.0;
    final left = w / (2 * count);
    final right = w - left;
    final cx = w / 2;

    final path = Path()
      ..moveTo(left, h)
      ..quadraticBezierTo(left, mid, left + r, mid)
      ..lineTo(cx - r, mid)
      ..quadraticBezierTo(cx, mid, cx, 0)
      ..quadraticBezierTo(cx, mid, cx + r, mid)
      ..lineTo(right - r, mid)
      ..quadraticBezierTo(right, mid, right, h);

    for (var i = 1; i < count - 1; i++) {
      final x = w * (2 * i + 1) / (2 * count);
      path
        ..moveTo(x, mid)
        ..lineTo(x, h);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.count != count;
}

/// Row of rounded segments, the first [filled] of them lit in [color].
class SegmentProgressBar extends StatelessWidget {
  final int total;
  final int filled;
  final Color? color;

  const SegmentProgressBar({
    super.key,
    required this.total,
    required this.filled,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final lit = color ?? context.colors.accent;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i < filled ? lit : Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(3),
                boxShadow: i < filled
                    ? [
                        BoxShadow(
                          color: lit.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Glass card holding an icon tile, a title, a subtitle and an optional
/// action underneath. Used for empty states.
class GlassEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContainer(
            width: 64,
            height: 64,
            radius: 22,
            tint: context.colors.accent,
            child: Icon(icon, size: 30, color: context.colors.accentLight),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Full-width translucent pill button with an accent icon and a trailing
/// chevron.
class GlassPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const GlassPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? context.colors.accent;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: GlassPill(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary call to action: a dark glass pill with an accent aurora glowing
/// along its bottom edge (Opal's "Continue" button, in our greens).
class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    final accentLight = context.colors.accentLight;
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onPressed == null && !isLoading ? 0.5 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GlassContainer(
              radius: 999,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1B1F1C), Color(0xFF0B0D0C)],
                          ),
                        ),
                      ),
                      // Aurora: a horizontal accent band, faded out towards the top.
                      ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.15, 0.7, 1],
                          colors: [
                            Colors.transparent,
                            Color(0x80FFFFFF),
                            Colors.white,
                          ],
                        ).createShader(rect),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              stops: const [0, 0.3, 0.6, 0.85, 1],
                              colors: [
                                accent.withValues(alpha: 0),
                                accent.withValues(alpha: 0.75),
                                accentLight.withValues(alpha: 0.85),
                                accentLight.withValues(alpha: 0.35),
                                accentLight.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
