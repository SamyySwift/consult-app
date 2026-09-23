import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';

class DeliveryAcknowledgementSheet extends StatefulWidget {
  final Future<void> Function(String signatureBase64) onConfirm;

  const DeliveryAcknowledgementSheet({super.key, required this.onConfirm});

  @override
  State<DeliveryAcknowledgementSheet> createState() => _DeliveryAcknowledgementSheetState();
}

class _DeliveryAcknowledgementSheetState extends State<DeliveryAcknowledgementSheet> {
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Proof of Handover',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Complete physical vehicle check and obtain recipient signature.',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 20),

              // Checkbox 1
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _goodCondition ? DriverColors.accent.withValues(alpha: 0.5) : const Color(0xFF262626),
                  ),
                ),
                child: CheckboxListTile(
                  value: _goodCondition,
                  onChanged: (v) => setState(() => _goodCondition = v ?? false),
                  title: const Text(
                    'Vehicle in pristine condition',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'No new scratches, dents, or interior damage verified.',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                  activeColor: DriverColors.accent,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 10),

              // Checkbox 2
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _inspected ? DriverColors.accent.withValues(alpha: 0.5) : const Color(0xFF262626),
                  ),
                ),
                child: CheckboxListTile(
                  value: _inspected,
                  onChanged: (v) => setState(() => _inspected = v ?? false),
                  title: const Text(
                    'Keys and documents handed over',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Recipient has received key fobs and inspection paperwork.',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                  activeColor: DriverColors.accent,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 20),

              // Signature Pad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recipient Signature',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: _clearSignature,
                    child: const Text('Clear', style: TextStyle(color: Color(0xFF888888))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2C2C2E)),
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF141414),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
              ),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator(color: DriverColors.accent))
                  : DriverButton(
                      label: 'Confirm & Complete Handover',
                      backgroundColor: DriverColors.accent,
                      foregroundColor: Colors.black,
                      onPressed: _submit,
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
