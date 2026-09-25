import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/motion.dart';
import '../../../core/constants/app_constants.dart';
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
    );

    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
              onPressed: _handleRegister,
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
