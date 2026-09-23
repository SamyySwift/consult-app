import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class SlideActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onSlideComplete;
  final double height;
  final double knobPadding;
  final Color? backgroundColor;
  final Color? knobColor;
  final Color? iconColor;
  final TextStyle? textStyle;
  final IconData icon;
  final double threshold;
  final bool allowTapToSlide;

  const SlideActionButton({
    super.key,
    this.label = 'Get Started',
    required this.onSlideComplete,
    this.height = 64.0,
    this.knobPadding = 8.0,
    this.backgroundColor,
    this.knobColor,
    this.iconColor,
    this.textStyle,
    this.icon = Icons.arrow_forward_rounded,
    this.threshold = 0.72,
    this.allowTapToSlide = true,
  });

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with TickerProviderStateMixin {
  late AnimationController _dragAnimController;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isCompleted = false;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _dragAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _dragAnimController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _animateTo(double target, double maxDrag, {VoidCallback? onDone}) {
    final start = _dragOffset;
    if ((start - target).abs() < 1.0) {
      _dragOffset = target;
      if (mounted) setState(() {});
      onDone?.call();
      return;
    }

    _dragAnimController.stop();
    _dragAnimController.reset();

    final curve = target == 0.0 ? Curves.easeOutBack : Curves.easeOutCubic;
    final animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _dragAnimController, curve: curve),
    );

    void tick() {
      if (mounted) {
        setState(() {
          _dragOffset = animation.value;
        });
      }
    }

    animation.addListener(tick);

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        animation.removeListener(tick);
        _dragAnimController.removeStatusListener(statusListener);
        if (mounted) {
          onDone?.call();
        }
      }
    }

    _dragAnimController.addStatusListener(statusListener);
    _dragAnimController.forward();
  }

  void _handleDragStart(DragStartDetails details) {
    if (_isCompleted) return;
    _dragAnimController.stop();
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted || maxDrag <= 0) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _handleDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted || maxDrag <= 0) return;
    setState(() {
      _isDragging = false;
    });

    if (_dragOffset >= maxDrag * widget.threshold) {
      _completeSlide(maxDrag);
    } else {
      _animateTo(0.0, maxDrag);
    }
  }

  void _handleDragCancel(double maxDrag) {
    if (_isCompleted) return;
    setState(() {
      _isDragging = false;
    });
    _animateTo(0.0, maxDrag);
  }

  void _completeSlide(double maxDrag) {
    _isCompleted = true;
    HapticFeedback.mediumImpact();
    _animateTo(maxDrag, maxDrag, onDone: () {
      widget.onSlideComplete();
      // Reset state in case screen is popped back to
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _isCompleted = false;
            _dragOffset = 0.0;
          });
        }
      });
    });
  }

  void _handleTap(double maxDrag) {
    if (_isCompleted || !widget.allowTapToSlide) return;
    _completeSlide(maxDrag);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? context.colors.accent;
    final knobColor = widget.knobColor ?? Colors.white;
    final iconColor = widget.iconColor ?? context.colors.accent;
    final knobSize = widget.height - (widget.knobPadding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - knobSize - (widget.knobPadding * 2)).clamp(0.0, double.infinity);
        final progress = maxDrag > 0 ? (_dragOffset / maxDrag).clamp(0.0, 1.0) : 0.0;
        final textOpacity = (1.0 - progress * 1.6).clamp(0.0, 1.0);
        final chevronOpacity = (1.0 - progress * 1.3).clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () => _handleTap(maxDrag),
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: (details) => _handleDragUpdate(details, maxDrag),
          onHorizontalDragEnd: (details) => _handleDragEnd(details, maxDrag),
          onHorizontalDragCancel: () => _handleDragCancel(maxDrag),
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Highlight track trailing the knob
                if (_dragOffset > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _dragOffset + knobSize + (widget.knobPadding * 2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Center Label
                Center(
                  child: Opacity(
                    opacity: textOpacity,
                    child: Text(
                      widget.label,
                      style: widget.textStyle ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                ),

                // Trailing Chevrons with shimmer
                Positioned(
                  right: 20,
                  child: AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (context, child) {
                      final shimmer = _shimmerAnim.value;
                      return Opacity(
                        opacity: chevronOpacity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: (0.45 * shimmer).clamp(0.0, 1.0)),
                              size: 20,
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: (0.7 * shimmer).clamp(0.0, 1.0)),
                              size: 20,
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: (0.95 * shimmer).clamp(0.0, 1.0)),
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Draggable Knob
                Positioned(
                  left: widget.knobPadding + _dragOffset,
                  child: AnimatedScale(
                    scale: _isDragging ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        color: knobColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                          if (_isDragging)
                            BoxShadow(
                              color: bgColor.withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
