import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/widgets/tap_target.dart';

class DeliveryAcknowledgementSheet extends StatefulWidget {
  final Future<void> Function(String signatureBase64) onConfirm;

  const DeliveryAcknowledgementSheet({super.key, required this.onConfirm});

  @override
  State<DeliveryAcknowledgementSheet> createState() =>
      _DeliveryAcknowledgementSheetState();
}

class _DeliveryAcknowledgementSheetState
    extends State<DeliveryAcknowledgementSheet> {
  bool _goodCondition = false;
  bool _inspected = false;

  final List<Offset?> _points = [];
  bool _isSubmitting = false;

  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _submit() async {
    if (!_goodCondition || !_inspected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check both acknowledgement boxes'),
          backgroundColor: Color(0xFF1C1C1E),
        ),
      );
      return;
    }
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a client signature'),
          backgroundColor: Color(0xFF1C1C1E),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final base64String = await _getSignatureBase64();
      await widget.onConfirm(base64String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save signature: $e'),
            backgroundColor: const Color(0xFF1C1C1E),
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _getSignatureBase64() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(300, 150);

    // Draw background
    final bgPaint = Paint()..color = const Color(0xFF141414);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final painter = SignaturePainter(_points);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (pngBytes == null) throw Exception('Signature encoding failed');
    return base64Encode(pngBytes.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return GlassBottomSheet(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GlassSheetHeader(
              icon: Icons.handshake_rounded,
              title: 'Proof of Handover',
              subtitle:
                  'Complete physical vehicle check and obtain recipient signature.',
            ),
            const SizedBox(height: 22),

            _CheckTile(
              checked: _goodCondition,
              title: 'Vehicle in pristine condition',
              subtitle: 'No new scratches, dents, or interior damage verified.',
              onChanged: (v) => setState(() => _goodCondition = v),
            ),
            const SizedBox(height: 10),
            _CheckTile(
              checked: _inspected,
              title: 'Keys and documents handed over',
              subtitle:
                  'Recipient has received key fobs and inspection paperwork.',
              onChanged: (v) => setState(() => _inspected = v),
            ),
            const SizedBox(height: 22),

            // Signature Pad
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recipient Signature',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                TapTarget(
                  onTap: _clearSignature,
                  child: GlassPill(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _points.isEmpty
                      ? Colors.white.withValues(alpha: 0.12)
                      : DriverColors.accent.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(22),
                color: const Color(0xFF141414),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    if (_points.isEmpty)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.draw_rounded,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sign here',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned.fill(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _points.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _points.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: SignaturePainter(_points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _isSubmitting
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DriverColors.accent,
                    ),
                  )
                : DriverButton(
                    label: 'Confirm & Complete Handover',
                    backgroundColor: DriverColors.accent,
                    foregroundColor: Colors.black,
                    onPressed: _submit,
                  ),
          ],
        ),
      ),
    );
  }
}

/// Glass row with a rounded check box, lit green once ticked.
class _CheckTile extends StatelessWidget {
  final bool checked;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _CheckTile({
    required this.checked,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!checked),
        // Checked rows get a green hairline instead of a glow.
        child: SurfaceCard(
          radius: 22,
          borderColor: checked
              ? DriverColors.accent.withValues(alpha: 0.6)
              : null,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: checked ? DriverColors.accentGradient : null,
                  color: checked ? null : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(9),
                  border: checked
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: checked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.black,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = DriverColors.accent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
