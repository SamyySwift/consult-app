import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/booking_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class Step5Documents extends StatefulWidget {
  final VoidCallback onNext;
  const Step5Documents({super.key, required this.onNext});

  @override
  State<Step5Documents> createState() => _Step5DocumentsState();
}

class _Step5DocumentsState extends State<Step5Documents> {
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null && mounted) {
        context.read<BookingProvider>().addDocument(file.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery')),
        );
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2))),
              SizedBox(height: 20),
              Text('Add Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: context.colors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.camera_alt_rounded, color: context.colors.accent, size: 20),
                ),
                title: Text('Take Photo'),
                subtitle: Text('Use camera to capture document'),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: context.colors.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.photo_library_rounded, color: context.colors.info, size: 20),
                ),
                title: Text('Choose from Gallery'),
                subtitle: Text('Select from your photo library'),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        final docs = prov.draft.documentPaths;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.upload_file_rounded,
                title: 'Documents',
                subtitle: 'Upload vehicle photos and proof of ownership',
              ),

              SizedBox(height: 24),

              // Required documents info
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: context.colors.info, size: 16),
                        SizedBox(width: 8),
                        Text('Required Documents', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.info)),
                      ],
                    ),
                    SizedBox(height: 8),
                    ...['Vehicle photos (front, rear, sides)', 'Proof of ownership / title', 'Valid ID of the vehicle owner'].map((doc) =>
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: context.colors.info, size: 14),
                            SizedBox(width: 8),
                            Text(doc, style: TextStyle(fontSize: 12, color: context.colors.info)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Text('Uploaded Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
              SizedBox(height: 12),

              // Document grid
              if (docs.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) => _DocumentTile(
                    path: docs[i],
                    onRemove: () => prov.removeDocument(i),
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Upload button
              GestureDetector(
                onTap: _showPickerOptions,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: Radius.circular(16),
                  color: context.colors.accent,
                  strokeWidth: 1.5,
                  dashPattern: [8, 4],
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: context.colors.accent.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.colors.accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_rounded, color: context.colors.accent, size: 28),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tap to upload document',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.accent),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'JPG, PNG up to 10MB',
                          style: TextStyle(fontSize: 12, color: context.colors.textLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              Text(
                '${docs.length} document${docs.length != 1 ? 's' : ''} uploaded',
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),

              SizedBox(height: 32),

              CustomButton(
                label: docs.isEmpty ? 'Skip for Now' : 'Continue',
                onPressed: widget.onNext,
              ),

              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _DocumentTile({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: context.colors.surfaceVariant,
              child: Icon(Icons.insert_drive_file_rounded, color: context.colors.textLight, size: 36),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: context.colors.error, shape: BoxShape.circle),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: context.colors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: context.colors.accent, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
