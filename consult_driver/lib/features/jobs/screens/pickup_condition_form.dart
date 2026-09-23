import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';
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
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Add Photo',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: DriverColors.accent),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Use your camera', style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: DriverColors.accent),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Pick from your photos', style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
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
          final path = '${dir.path}/pickup_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
          content: Text('Please provide a text description of the vehicle condition.'),
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
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const Text(
              'Vehicle Pickup Condition',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Document the condition of the vehicle at pickup.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
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
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),

            // Images Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Photos',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo, color: DriverColors.accent),
                )
              ],
            ),
            if (_images.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.only(top: 8),
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
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
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
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Audio Section
            const Text(
              'Voice Note',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: CircleAvatar(
                    backgroundColor: _isRecording ? DriverColors.error : const Color(0xFF222222),
                    radius: 24,
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.white : DriverColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isRecording 
                      ? 'Recording...' 
                      : (_audioPath != null ? 'Voice note recorded.' : 'Tap to record voice note'),
                    style: TextStyle(
                      color: _isRecording ? DriverColors.error : Colors.white70,
                      fontStyle: _audioPath != null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                if (_audioPath != null && !_isRecording)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _audioPath = null;
                        _audioFile = null;
                      });
                    },
                  )
              ],
            ),
            
            const SizedBox(height: 32),

            if (_isSubmitting)
              const Center(child: CircularProgressIndicator(color: DriverColors.accent))
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
