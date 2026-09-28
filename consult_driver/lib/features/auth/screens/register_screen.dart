import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/motion.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/tap_target.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/driver_text_field.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_sheet_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Partner companies a driver can drive for, managed in the admin dashboard
  List<({String id, String name})>? _partners;
  bool _partnersLoading = true;
  bool _partnersFailed = false;
  String? _partnerId;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _partnersLoading = true;
      _partnersFailed = false;
    });
    final res = await ApiClient.instance.get('/api/driver/partners');
    if (!mounted) return;
    setState(() {
      _partnersLoading = false;
      if (res.isSuccess && res.data is List) {
        _partners = [
          for (final p in res.data as List)
            if (p is Map && p['id'] != null && p['name'] != null)
              (id: p['id'].toString(), name: p['name'].toString()),
        ];
        // Drop a selection that's no longer offered
        if (_partners!.every((p) => p.id != _partnerId)) _partnerId = null;
      } else {
        _partnersFailed = true;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      partnerId: _partnerId!,
    );

    if (!mounted) return;

    if (!success && (auth.errorMessage ?? '').contains('no longer available')) {
      // The admin deactivated the chosen company while the form was open
      _loadPartners();
    }

    if (success) {
      if (auth.needsOtp) {
        final email = _emailController.text.trim();
        context.go('${AppRoutes.otp}?email=${Uri.encodeComponent(email)}');
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Text(auth.errorMessage ?? 'Registration failed', style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Widget _buildCompanyPicker() {
    final label = Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        'Company You Drive For',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );

    Widget field;
    if (_partnersLoading) {
      field = const InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.business_outlined, color: DriverColors.textSecondary, size: 20),
          hintText: 'Loading companies…',
        ),
        child: SizedBox(height: 20, child: Align(alignment: Alignment.centerLeft, child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
      );
    } else if (_partnersFailed) {
      field = _PickerNotice(
        text: "Couldn't load companies. Check your connection.",
        actionLabel: 'Retry',
        onAction: _loadPartners,
      );
    } else if (_partners!.isEmpty) {
      field = const _PickerNotice(
        text: 'No partner companies are available yet, so sign-up is closed. Please contact support.',
      );
    } else {
      field = DropdownButtonFormField<String>(
        initialValue: _partnerId,
        isExpanded: true,
        dropdownColor: DriverColors.surface,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: DriverColors.textSecondary),
        style: GoogleFonts.inter(fontSize: 15, color: DriverColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          hintText: 'Select your company',
          prefixIcon: Icon(Icons.business_outlined, color: DriverColors.textSecondary, size: 20),
        ),
        items: [
          for (final p in _partners!)
            DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (id) => setState(() => _partnerId = id),
        validator: (id) => id == null ? 'Please select the company you drive for' : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [label, const SizedBox(height: 8), field],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Sign-up needs a company, so it's blocked until one can be chosen
    final canSubmit = _partners != null && _partners!.isNotEmpty;

    return AuthSheetLayout(
      sheetHeight: 0.8,
      onBack: () => context.go(AppRoutes.login),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              const TextSpan(
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6),
                children: [
                  TextSpan(text: 'Driver '),
                  TextSpan(text: 'Application', style: TextStyle(color: DriverColors.accent)),
                ],
              ),
              textAlign: TextAlign.center,
            ).motionAware(context).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 6),

            Text(
              'Enter your credentials to join our logistics network. Approved within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), height: 1.4, fontSize: 14),
            ).motionAware(context).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 12),
              child: Text(
                'Personal Information',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DriverTextField(
                    label: 'First Name',
                    hint: 'John',
                    controller: _firstNameController,
                    validator: (v) => AppValidators.validateRequired(v, field: 'First name'),
                  ).motionAware(context, delay: 100.ms).fadeIn().slideY(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DriverTextField(
                    label: 'Last Name',
                    hint: 'Doe',
                    controller: _lastNameController,
                    validator: (v) => AppValidators.validateRequired(v, field: 'Last name'),
                  ).motionAware(context, delay: 150.ms).fadeIn().slideY(),
                ),
              ],
            ),

            const SizedBox(height: 18),

            DriverTextField(
              label: 'Email Address',
              hint: 'driver@consultlogistics.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              validator: AppValidators.validateEmail,
            ).motionAware(context, delay: 200.ms).fadeIn().slideY(),

            const SizedBox(height: 18),

            DriverTextField(
              label: 'Phone Number',
              hint: '+44 7700 900077',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              controller: _phoneController,
              validator: AppValidators.validatePhone,
            ).motionAware(context, delay: 250.ms).fadeIn().slideY(),

            const SizedBox(height: 18),

            _buildCompanyPicker().motionAware(context, delay: 275.ms).fadeIn().slideY(),

            const SizedBox(height: 18),

            DriverTextField(
              label: 'Security Password',
              hint: 'Create a password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              controller: _passwordController,
              validator: AppValidators.validatePassword,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFF777777),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ).motionAware(context, delay: 300.ms).fadeIn().slideY(),

            const SizedBox(height: 30),

            DriverButton(
              label: 'Submit Application',
              onPressed: canSubmit ? _handleRegister : null,
              isLoading: auth.isLoading,
            ).motionAware(context, delay: 400.ms).fadeIn().scale(),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already a driver? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                TapTarget(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands in for the company dropdown when there's nothing to choose from.
class _PickerNotice extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PickerNotice({required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: DriverColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: DriverColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: DriverColors.textPrimary, fontSize: 13, height: 1.35)),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
