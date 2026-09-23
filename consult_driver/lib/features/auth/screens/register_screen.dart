import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/driver_text_field.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

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
      context.go(AppRoutes.dashboard);
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Driver Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ).animate().fadeIn().slideX(),
              
              const SizedBox(height: 6),
              
              const Text(
                'Enter your credentials to join our logistics network. Approved within 24 hours.',
                style: TextStyle(color: Color(0xFF888888), height: 1.4, fontSize: 13),
              ).animate().fadeIn().slideX(),
              
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: DriverTextField(
                      label: 'First Name',
                      hint: 'John',
                      controller: _firstNameController,
                      validator: (v) => AppValidators.validateRequired(v, field: 'First name'),
                    ).animate(delay: 100.ms).fadeIn().slideY(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DriverTextField(
                      label: 'Last Name',
                      hint: 'Doe',
                      controller: _lastNameController,
                      validator: (v) => AppValidators.validateRequired(v, field: 'Last name'),
                    ).animate(delay: 150.ms).fadeIn().slideY(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              DriverTextField(
                label: 'Email Address',
                hint: 'driver@consultlogistics.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: AppValidators.validateEmail,
              ).animate(delay: 200.ms).fadeIn().slideY(),
              
              const SizedBox(height: 20),
              
              DriverTextField(
                label: 'Phone Number',
                hint: '+44 7700 900077',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                validator: AppValidators.validatePhone,
              ).animate(delay: 250.ms).fadeIn().slideY(),
              
              const SizedBox(height: 20),
              
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
              ).animate(delay: 300.ms).fadeIn().slideY(),

              const SizedBox(height: 36),

              DriverButton(
                label: 'Submit Application',
                onPressed: _handleRegister,
                isLoading: auth.isLoading,
              ).animate(delay: 400.ms).fadeIn().scale(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
