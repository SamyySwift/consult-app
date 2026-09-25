import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/widgets/tap_target.dart';
import '../providers/job_provider.dart';
import '../models/job_model.dart';

class PickupConditionForm extends StatefulWidget {
  final JobModel job;

  const PickupConditionForm({super.key, required this.job});

  @override
  State<PickupConditionForm> createState() => _PickupConditionFormState();
}

class _PickupConditionFormState extends State<PickupConditionForm> {
  final _descriptionController = TextEditingController();
  final List<File> _images = [];
  File? _audioFile;

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Add Photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            GlassOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Use your camera',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 10),
            GlassOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Pick from your photos',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();

    if (source == ImageSource.gallery) {
      // Allow picking multiple images from gallery
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    } else {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          if (path != null) {
            _audioPath = path;
            _audioFile = File(path);
          }
        });
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path =
              '${dir.path}/pickup_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
          setState(() {
            _isRecording = true;
            _audioPath = null;
            _audioFile = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Audio recording error: $e');
    }
  }

  Future<void> _submit() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide a text description of the vehicle condition.',
          ),
          backgroundColor: DriverColors.error,
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture at least one photo of the vehicle.'),
          backgroundColor: DriverColors.error,
        ),
      );
      return;
    }

    final hasLocation = await DriverLocationAccess.ensure(
      context,
      reason:
          'Your client tracks this delivery using your location. Turn it on to confirm pickup.',
    );
    if (!hasLocation || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<JobProvider>().submitPickupCondition(
        jobId: widget.job.id,
        description: _descriptionController.text.trim(),
        imageFiles: _images,
        audioFile: _audioFile,
      );

      if (mounted) {
        Navigator.of(context).pop(); // close bottom sheet
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: DriverColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBottomSheet(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GlassSheetHeader(
              icon: Icons.fact_check_rounded,
              title: 'Vehicle Pickup Condition',
              subtitle: 'Document the condition of the vehicle at pickup.',
            ),
            const SizedBox(height: 24),

            // Description Text Field
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe any scratches, dents, or notes...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: DriverColors.accent,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 24),

            // Images Section
            Row(
              children: [
                const Text(
                  'Photos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                if (_images.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${_images.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 15,
                    ),
                  ),
                ],
                const Spacer(),
                TapTarget(
                  onTap: _pickImage,
                  child: GlassPill(
                    tint: DriverColors.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: DriverColors.accentLight,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: DriverColors.accentLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_images.isEmpty)
              GestureDetector(
                onTap: _pickImage,
                child: SurfaceCard(
                  radius: 22,
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to add at least one photo',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            image: DecorationImage(
                              image: FileImage(_images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 18,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _images.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Audio Section
            const Text(
              'Voice Note',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isRecording
                            ? null
                            : DriverColors.accentGradient,
                        color: _isRecording ? DriverColors.error : null,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? DriverColors.error
                                        : DriverColors.accent)
                                    .withValues(alpha: 0.45),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isRecording ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isRecording
                          ? 'Recording...'
                          : (_audioPath != null
                                ? 'Voice note recorded.'
                                : 'Tap to record voice note'),
                      style: TextStyle(
                        color: _isRecording
                            ? DriverColors.error
                            : Colors.white70,
                        fontStyle: _audioPath != null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                  if (_audioPath != null && !_isRecording)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _audioPath = null;
                          _audioFile = null;
                        });
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            if (_isSubmitting)
              const Center(
                child: CircularProgressIndicator(color: DriverColors.accent),
              )
            else
              DriverButton(
                label: 'Submit & Confirm Pickup',
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
