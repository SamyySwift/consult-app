import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/motion.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/driver_text_field.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_sheet_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    
    if (success) {
      if (auth.driver?.isProfileCompleted == true) {
        context.go(AppRoutes.dashboard);
      } else {
        context.go(AppRoutes.completeProfile);
      }
    } else {
      if (auth.needsOtp) {
        final email = _emailController.text.trim();
        context.go('${AppRoutes.otp}?email=${Uri.encodeComponent(email)}');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Text(auth.errorMessage ?? 'Login failed', style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthSheetLayout(
      sheetHeight: 0.68,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text.rich(
              const TextSpan(
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8),
                children: [
                  TextSpan(text: 'Driver '),
                  TextSpan(text: 'Portal', style: TextStyle(color: DriverColors.accent)),
                ],
              ),
              textAlign: TextAlign.center,
            ).motionAware(context, delay: 100.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 6),

            Text(
              'Sign in to access your logistics mission board',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
            ).motionAware(context, delay: 200.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 28),

            DriverTextField(
              label: 'Driver Email',
              hint: 'driver@consultlogistics.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              validator: AppValidators.validateEmail,
            ).motionAware(context, delay: 300.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 18),

            DriverTextField(
              label: 'Password',
              hint: '••••••••',
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
            ).motionAware(context, delay: 400.ms).fadeIn().slideY(begin: 0.05),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                // No self-serve reset yet: send the driver to dispatch support.
                onPressed: () => emailSupport(
                  context,
                  subject: 'Driver password reset',
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: DriverColors.accent, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ).motionAware(context, delay: 500.ms).fadeIn(),

            const SizedBox(height: 16),

            DriverButton(
              label: 'Login',
              onPressed: _handleLogin,
              isLoading: auth.isLoading,
            ).motionAware(context, delay: 600.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('New driver? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Apply for Dispatch',
                    style: TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ).motionAware(context, delay: 700.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
