import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/driver_button.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
  }

  Widget _buildAvatar(DriverModel driver) {
    if (driver.avatarUrl != null && driver.avatarUrl!.isNotEmpty) {
      try {
        if (driver.avatarUrl!.startsWith('data:image')) {
          final base64Data = driver.avatarUrl!.split(',').last;
          return ClipOval(
            child: Image.memory(
              base64Decode(base64Data),
              width: 82,
              height: 82,
              fit: BoxFit.cover,
            ),
          );
        } else if (driver.avatarUrl!.startsWith('http')) {
          return ClipOval(
            child: Image.network(
              driver.avatarUrl!,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (e) {
        debugPrint('Avatar decode error: $e');
      }
    }

    return Text(
      driver.initials,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: DriverColors.accent,
      ),
    );
  }

  String _formatNin(String? nin) {
    if (nin == null || nin.isEmpty) return 'Not submitted';
    if (nin.length >= 7) {
      return '${nin.substring(0, 3)}•••••${nin.substring(nin.length - 3)}';
    }
    return nin;
  }

  int _calculateCompletionPercentage(DriverModel driver) {
    int total = 8;
    int completed = 0;
    if (driver.fullName.isNotEmpty && driver.fullName != 'Driver') completed++;
    if (driver.phone.isNotEmpty) completed++;
    if (driver.dateOfBirth != null && driver.dateOfBirth!.isNotEmpty) completed++;
    if (driver.residentialAddress != null && driver.residentialAddress!.isNotEmpty) completed++;
    if (driver.stateLga != null && driver.stateLga!.isNotEmpty) completed++;
    if (driver.emergencyContactName != null && driver.emergencyContactName!.isNotEmpty) completed++;
    if (driver.ninNumber != null && driver.ninNumber!.isNotEmpty) completed++;
    if (driver.driverLicenseImage != null && driver.driverLicenseImage!.isNotEmpty) completed++;

    return ((completed / total) * 100).round();
  }

  List<String> _getMissingFields(DriverModel driver) {
    final missing = <String>[];
    if (driver.dateOfBirth == null || driver.dateOfBirth!.isEmpty) missing.add('Date of Birth');
    if (driver.residentialAddress == null || driver.residentialAddress!.isEmpty) missing.add('Residential Address');
    if (driver.stateLga == null || driver.stateLga!.isEmpty) missing.add('State/LGA');
    if (driver.emergencyContactName == null || driver.emergencyContactName!.isEmpty) missing.add('Emergency Contact');
    if (driver.ninNumber == null || driver.ninNumber!.isEmpty) missing.add('NIN Number');
    if (driver.driverLicenseImage == null || driver.driverLicenseImage!.isEmpty) missing.add('Licence Image');
    return missing;
  }

  void _showLicenceDialog(BuildContext context, DriverModel driver) {
    if (driver.driverLicenseImage == null || driver.driverLicenseImage!.isEmpty) return;
    Widget img;
    try {
      if (driver.driverLicenseImage!.startsWith('data:image')) {
        final base64Data = driver.driverLicenseImage!.split(',').last;
        img = Image.memory(base64Decode(base64Data), fit: BoxFit.contain);
      } else {
        img = Image.network(driver.driverLicenseImage!, fit: BoxFit.contain);
      }
    } catch (_) {
      img = const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60);
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF161616),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Driver’s Licence Document',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: img,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicencePreview(BuildContext context, DriverModel driver) {
    if (driver.driverLicenseImage != null && driver.driverLicenseImage!.isNotEmpty) {
      Widget imageWidget;
      try {
        if (driver.driverLicenseImage!.startsWith('data:image')) {
          final base64Data = driver.driverLicenseImage!.split(',').last;
          imageWidget = Image.memory(
            base64Decode(base64Data),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 150,
          );
        } else if (driver.driverLicenseImage!.startsWith('http')) {
          imageWidget = Image.network(
            driver.driverLicenseImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 150,
          );
        } else {
          imageWidget = const SizedBox();
        }
      } catch (e) {
        imageWidget = const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
        );
      }

      return GestureDetector(
        onTap: () => _showLicenceDialog(context, driver),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DriverColors.accent.withValues(alpha: 0.4)),
            color: const Color(0xFF161616),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  imageWidget,
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: DriverColors.accent, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Licence Document Uploaded',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.completeProfile),
                      child: const Text(
                        'Change',
                        style: TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_outlined, color: Color(0xFFFF9800), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver’s Licence Document',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Upload required to activate dispatch missions',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.completeProfile),
            style: TextButton.styleFrom(
              backgroundColor: DriverColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.driver;

    if (driver == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: DriverColors.accent)),
      );
    }

    final percentage = _calculateCompletionPercentage(driver);
    final missingFields = _getMissingFields(driver);
    final isFullyCompleted = driver.isProfileCompleted || percentage == 100;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Driver Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => auth.fetchProfile(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: DriverColors.accent,
        backgroundColor: const Color(0xFF161616),
        onRefresh: () => auth.fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // Header Profile Info Card
              // -------------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: DriverColors.accent, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: _buildAvatar(driver),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      driver.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          driver.email,
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                        ),
                        if (driver.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded, color: DriverColors.accent, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191919),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF262626)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${driver.rating} Rating  •  ${driver.totalJobs} Completed Missions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Action button inside header
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.completeProfile),
                        icon: Icon(
                          isFullyCompleted ? Icons.edit_note_rounded : Icons.assignment_turned_in_rounded,
                          size: 18,
                          color: DriverColors.accent,
                        ),
                        label: Text(
                          isFullyCompleted ? 'Edit KYC Profile' : 'Complete Profile Now',
                          style: const TextStyle(
                            color: DriverColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: DriverColors.accent.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.05),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // KYC Profile Status & Progress Card
              // -------------------------------------------------------------
              GestureDetector(
                onTap: () => context.push(AppRoutes.completeProfile),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isFullyCompleted
                        ? DriverColors.accent.withValues(alpha: 0.08)
                        : const Color(0xFF201608),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFullyCompleted
                          ? DriverColors.accent.withValues(alpha: 0.4)
                          : const Color(0xFFFF9800),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isFullyCompleted
                                  ? DriverColors.accent.withValues(alpha: 0.2)
                                  : const Color(0xFFFF9800).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFullyCompleted
                                  ? Icons.verified_user_rounded
                                  : Icons.warning_amber_rounded,
                              color: isFullyCompleted
                                  ? DriverColors.accent
                                  : const Color(0xFFFF9800),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFullyCompleted
                                      ? 'KYC Profile Complete (100%)'
                                      : 'Action Required: Complete Profile ($percentage%)',
                                  style: TextStyle(
                                    color: isFullyCompleted
                                        ? Colors.white
                                        : const Color(0xFFFFB74D),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isFullyCompleted
                                      ? 'Personal details, emergency contact & identification on file.'
                                      : 'Submit all required personal and verification fields to activate missions.',
                                  style: const TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isFullyCompleted ? DriverColors.accent : const Color(0xFFFFB74D),
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFF2A2A2A),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFullyCompleted ? DriverColors.accent : const Color(0xFFFF9800),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      if (!isFullyCompleted && missingFields.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: missingFields.map((f) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E200C),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Color(0xFFFF9800), size: 6),
                                const SizedBox(width: 4),
                                Text(
                                  f,
                                  style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 14),
                        DriverButton(
                          label: 'Complete Profile Now',
                          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                          onPressed: () => context.push(AppRoutes.completeProfile),
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate(delay: 50.ms).fadeIn(),

              const SizedBox(height: 22),

              // -------------------------------------------------------------
              // Section: Personal & Contact Information
              // -------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Driver’s Personal Information',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.completeProfile),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: DriverColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Legal Name',
                  value: driver.fullName,
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: driver.email,
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: driver.phone.isNotEmpty ? driver.phone : 'Not provided',
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: driver.dateOfBirth ?? 'Not provided',
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.home_outlined,
                  label: 'Residential Address',
                  value: driver.residentialAddress ?? 'Not provided',
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'State / LGA',
                  value: driver.stateLga ?? 'Not provided',
                ),
              ]).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 22),

              // -------------------------------------------------------------
              // Section: Emergency Contact / Next of Kin
              // -------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency Contact / Next of Kin',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.completeProfile),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: DriverColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.contact_phone_outlined,
                  label: 'Contact Name',
                  value: driver.emergencyContactName ?? 'Not provided',
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.phone_in_talk_outlined,
                  label: 'Emergency Phone',
                  value: driver.emergencyContactPhone ?? 'Not provided',
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.family_restroom_rounded,
                  label: 'Relationship',
                  value: driver.emergencyContactRelationship ?? 'Not provided',
                ),
              ]).animate(delay: 120.ms).fadeIn(),

              const SizedBox(height: 22),

              // -------------------------------------------------------------
              // Section: Identification & Verification
              // -------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Identification & KYC Verification',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.completeProfile),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: DriverColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.credit_card_rounded,
                  label: 'NIN Number',
                  value: _formatNin(driver.ninNumber),
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Driver’s Licence',
                  value: driver.licenseNumber ?? 'LG-2023-0048291',
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _buildLicencePreview(context, driver),
              ]).animate(delay: 140.ms).fadeIn(),

              const SizedBox(height: 22),

              // -------------------------------------------------------------
              // Section: Vehicle & Logistics Rig
              // -------------------------------------------------------------
              const Text(
                'Vehicle & Logistics Rig',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 10),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Vehicle Rig Type',
                  value: driver.vehicleType ?? 'Flatbed Tow Truck',
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _InfoRow(
                  icon: Icons.directions_car_outlined,
                  label: 'Transport Rig Plate',
                  value: driver.vehiclePlate ?? 'LND-394-FY',
                ),
              ]).animate(delay: 160.ms).fadeIn(),

              const SizedBox(height: 24),

              // -------------------------------------------------------------
              // Section: Account & System Settings
              // -------------------------------------------------------------
              const Text(
                'Account & System',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 10),
              _buildInfoCard([
                _SettingsTile(
                  icon: Icons.edit_note_rounded,
                  title: 'Complete / Edit KYC Profile',
                  onTap: () => context.push(AppRoutes.completeProfile),
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Push Dispatch Alerts',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _SettingsTile(
                  icon: Icons.security_rounded,
                  title: 'Security & Access',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Dispatch Operations Support',
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFF1E1E1E)),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  textColor: const Color(0xFFFF5252),
                  iconColor: const Color(0xFFFF5252),
                  onTap: () async {
                    await auth.logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ]).animate(delay: 180.ms).fadeIn(),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: DriverColors.accent, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? DriverColors.accent, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor ?? Colors.white,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF444444), size: 18),
      ),
    );
  }
}
