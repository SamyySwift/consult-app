import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/driver_text_field.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

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
      context.go(AppRoutes.dashboard);
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header Hero
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DriverColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.directions_car_filled_rounded, color: DriverColors.accent, size: 28),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Driver Portal',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),
                  
                  const SizedBox(height: 6),
                  
                  const Text(
                    'Sign in to access your logistics mission board',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      DriverTextField(
                        label: 'Driver Email',
                        hint: 'driver@consultlogistics.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: AppValidators.validateEmail,
                      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),
                      
                      const SizedBox(height: 20),
                      
                      DriverTextField(
                        label: 'Access Key (Password)',
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
                      ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                        ),
                      ).animate(delay: 500.ms).fadeIn(),
                      
                      const SizedBox(height: 24),
                      
                      DriverButton(
                        label: 'Authenticate & Enter',
                        onPressed: _handleLogin,
                        isLoading: auth.isLoading,
                      ).animate(delay: 600.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('New driver? ', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.register),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Apply for Dispatch', style: TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ).animate(delay: 700.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
