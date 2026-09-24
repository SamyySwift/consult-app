import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/driver_text_field.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info Controllers
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _dobController = TextEditingController();
  final _residentialAddressController = TextEditingController();
  final _stateLgaController = TextEditingController();

  // Emergency Contact Controllers
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  String _emergencyRelationship = 'Next of Kin';

  // Identification & Verification Controllers
  final _ninController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  // Images
  File? _avatarFile;
  String? _avatarBase64;
  File? _licenseImageFile;
  String? _licenseImageBase64;

  final _picker = ImagePicker();

  static const List<String> _relationships = [
    'Next of Kin',
    'Spouse',
    'Parent',
    'Sibling',
    'Child',
    'Relative',
    'Business Partner',
    'Friend',
  ];

  static const List<String> _nigerianStates = [
    'Lagos',
    'Abuja (FCT)',
    'Rivers',
    'Ogun',
    'Oyo',
    'Kano',
    'Delta',
    'Edo',
    'Kaduna',
    'Anambra',
    'Enugu',
    'Akwa Ibom',
    'Cross River',
    'Ondo',
    'Osun',
    'Kwara',
    'Plateau',
    'Imo',
    'Abia',
    'Bayelsa',
    'Other',
  ];
  String _selectedState = 'Lagos';

  @override
  void initState() {
    super.initState();
    final driver = context.read<AuthProvider>().driver;
    final pendingEmail = context.read<AuthProvider>().pendingEmail;

    final initialName = driver != null && driver.fullName.isNotEmpty
        ? driver.fullName
        : '${driver?.firstName ?? ''} ${driver?.lastName ?? ''}'.trim();

    _fullNameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: driver?.phone ?? '');
    _emailController = TextEditingController(text: driver?.email.isNotEmpty == true ? driver!.email : (pendingEmail ?? ''));

    if (driver?.dateOfBirth != null) _dobController.text = driver!.dateOfBirth!;
    if (driver?.residentialAddress != null) _residentialAddressController.text = driver!.residentialAddress!;
    if (driver?.stateLga != null) _stateLgaController.text = driver!.stateLga!;
    if (driver?.emergencyContactName != null) _emergencyNameController.text = driver!.emergencyContactName!;
    if (driver?.emergencyContactPhone != null) _emergencyPhoneController.text = driver!.emergencyContactPhone!;
    if (driver?.emergencyContactRelationship != null &&
        _relationships.contains(driver!.emergencyContactRelationship)) {
      _emergencyRelationship = driver.emergencyContactRelationship!;
    }
    if (driver?.ninNumber != null) _ninController.text = driver!.ninNumber!;
    if (driver?.licenseNumber != null) _licenseNumberController.text = driver!.licenseNumber!;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _residentialAddressController.dispose();
    _stateLgaController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _ninController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Profile Photo',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: DriverColors.accent),
                title: const Text('Take a Selfie', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: DriverColors.accent),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        setState(() {
          _avatarFile = File(picked.path);
          _avatarBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      debugPrint('Avatar pick error: $e');
    }
  }

  Future<void> _pickLicenseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Driver’s Licence',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: DriverColors.accent),
                title: const Text('Take Photo of Licence', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: DriverColors.accent),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        setState(() {
          _licenseImageFile = File(picked.path);
          _licenseImageBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      debugPrint('Licence image pick error: $e');
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 25, 1, 1);
    final firstDate = DateTime(now.year - 70);
    final lastDate = DateTime(now.year - 18, now.month, now.day); // Must be at least 18

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DriverColors.accent,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF161616)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth.'),
          backgroundColor: DriverColors.error,
        ),
      );
      return;
    }

    if (_licenseImageBase64 == null && context.read<AuthProvider>().driver?.driverLicenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image of your Driver’s Licence.'),
          backgroundColor: DriverColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final stateLga = '$_selectedState, ${_stateLgaController.text.trim()}'.trim();

    final success = await auth.completeProfile(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      residentialAddress: _residentialAddressController.text.trim(),
      stateLga: stateLga,
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      emergencyContactRelationship: _emergencyRelationship,
      ninNumber: _ninController.text.trim(),
      avatarUrl: _avatarBase64,
      driverLicenseImage: _licenseImageBase64,
      licenseNumber: _licenseNumberController.text.trim().isNotEmpty
          ? _licenseNumberController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully! Welcome to Carpital Consult.'),
          backgroundColor: DriverColors.accent,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update profile. Please try again.'),
          backgroundColor: DriverColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
        title: const Text(
          'Complete Driver Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DriverColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DriverColors.accent.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'KYC STEP',
                  style: TextStyle(
                    color: DriverColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Intro Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DriverColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: DriverColors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Identity & Verification',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Provide your verified personal details and identification documents to activate full job dispatching.',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 24),

                // -----------------------------------------------------------
                // SECTION 1: Personal Information
                // -----------------------------------------------------------
                _buildSectionHeader('1. Driver’s Personal Information', Icons.person_outline_rounded),

                const SizedBox(height: 16),

                // Profile Photo Avatar
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1C),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: DriverColors.accent.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                image: _avatarFile != null
                                    ? DecorationImage(
                                        image: FileImage(_avatarFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _avatarFile == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: Color(0xFF666666),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: DriverColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _avatarFile != null ? 'Change Profile Photo' : 'Upload Profile Photo',
                        style: const TextStyle(
                          color: DriverColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Full Legal Name
                DriverTextField(
                  label: 'Full Legal Name',
                  hint: 'e.g. John Olumide Adeleke',
                  prefixIcon: Icons.badge_outlined,
                  controller: _fullNameController,
                  validator: (v) => AppValidators.validateRequired(v, field: 'Full legal name'),
                ),

                const SizedBox(height: 16),

                // Date of Birth
                GestureDetector(
                  onTap: _selectDateOfBirth,
                  child: AbsorbPointer(
                    child: DriverTextField(
                      label: 'Date of Birth',
                      hint: 'DD/MM/YYYY',
                      prefixIcon: Icons.calendar_today_rounded,
                      controller: _dobController,
                      validator: (v) => AppValidators.validateRequired(v, field: 'Date of birth'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone Number
                DriverTextField(
                  label: 'Phone Number',
                  hint: '+234 801 234 5678',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: AppValidators.validatePhone,
                ),

                const SizedBox(height: 16),

                // Email Address
                DriverTextField(
                  label: 'Email Address',
                  hint: 'driver@carpitalconsult.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: AppValidators.validateEmail,
                ),

                const SizedBox(height: 16),

                // Residential Address
                DriverTextField(
                  label: 'Residential Address',
                  hint: 'House number, Street name, Estate / Area',
                  prefixIcon: Icons.home_outlined,
                  controller: _residentialAddressController,
                  validator: (v) => AppValidators.validateRequired(v, field: 'Residential address'),
                ),

                const SizedBox(height: 16),

                // State / LGA
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'State',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF262626)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedState,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1A1A1A),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                                items: _nigerianStates.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedState = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: DriverTextField(
                        label: 'LGA / District',
                        hint: 'e.g. Ikeja / Lekki',
                        controller: _stateLgaController,
                        validator: (v) => AppValidators.validateRequired(v, field: 'LGA / District'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // -----------------------------------------------------------
                // SECTION 2: Emergency Contact / Next of Kin
                // -----------------------------------------------------------
                _buildSectionHeader('2. Emergency Contact / Next of Kin', Icons.contact_phone_outlined),

                const SizedBox(height: 16),

                DriverTextField(
                  label: 'Next of Kin / Contact Full Name',
                  hint: 'e.g. Sarah Adeleke',
                  prefixIcon: Icons.person_pin_circle_outlined,
                  controller: _emergencyNameController,
                  validator: (v) => AppValidators.validateRequired(v, field: 'Emergency contact name'),
                ),

                const SizedBox(height: 16),

                DriverTextField(
                  label: 'Emergency Phone Number',
                  hint: '+234 802 345 6789',
                  prefixIcon: Icons.phone_in_talk_outlined,
                  keyboardType: TextInputType.phone,
                  controller: _emergencyPhoneController,
                  validator: AppValidators.validatePhone,
                ),

                const SizedBox(height: 16),

                // Relationship to emergency contact
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relationship to Emergency Contact',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF262626)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _emergencyRelationship,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1A1A),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                          items: _relationships.map((r) {
                            return DropdownMenuItem(value: r, child: Text(r));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _emergencyRelationship = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // -----------------------------------------------------------
                // SECTION 3: Identification & Verification
                // -----------------------------------------------------------
                _buildSectionHeader('3. Identification & Verification', Icons.document_scanner_outlined),

                const SizedBox(height: 16),

                // NIN Number
                DriverTextField(
                  label: 'NIN Number (National Identity)',
                  hint: '11-digit National Identity Number',
                  prefixIcon: Icons.credit_card_rounded,
                  keyboardType: TextInputType.number,
                  controller: _ninController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'NIN number is required';
                    final clean = v.trim().replaceAll(' ', '');
                    if (clean.length != 11 || int.tryParse(clean) == null) {
                      return 'Please enter a valid 11-digit NIN';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Driver's Licence Number (Optional/prefilled)
                DriverTextField(
                  label: 'Driver’s Licence Number',
                  hint: 'e.g. LG-2023-0048291',
                  prefixIcon: Icons.drive_eta_outlined,
                  controller: _licenseNumberController,
                  validator: (v) => AppValidators.validateRequired(v, field: 'Licence number'),
                ),

                const SizedBox(height: 16),

                // Driver's Licence Image Upload Card
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver’s Licence Image Upload',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickLicenseImage,
                      child: Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _licenseImageFile != null
                                ? DriverColors.accent
                                : const Color(0xFF2E2E2E),
                            width: 1.5,
                          ),
                        ),
                        child: _licenseImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.file(
                                        _licenseImageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: DriverColors.accent, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Change Image',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: DriverColors.accent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: DriverColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Upload Driver’s Licence Photo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Clear photo showing name, photo & expiry date',
                                    style: TextStyle(
                                      color: Color(0xFF777777),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Submit Button
                DriverButton(
                  label: 'Complete & Save Profile',
                  onPressed: auth.isLoading ? null : _handleSubmit,
                  isLoading: auth.isLoading,
                ).animate(delay: 200.ms).fadeIn().scale(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DriverColors.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
