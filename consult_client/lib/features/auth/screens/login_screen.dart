import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go(AppConstants.routeHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed. Please try again.'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            children: [
              // Top hero image
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.55,
                child: Image.network(
                  'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?q=80&w=3540&auto=format&fit=crop',
                  fit: BoxFit.cover,
                ),
              ),

              // Back button to Register page
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppConstants.routeRegister);
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),

              // Bottom sheet form
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 8),

                          Text(
                            'Log in to continue your\nseamless journey',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15, 
                              color: context.colors.textSecondary,
                              height: 1.5,
                            ),
                          ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 40),

                          CustomTextField(
                            hint: 'Enter Your Email',
                            controller: _emailController,
                            validator: AppValidators.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 24),

                          CustomTextField(
                            hint: 'Enter Your Password',
                            controller: _passwordController,
                            validator: AppValidators.validatePassword,
                            obscureText: _obscurePassword,
                            autofillHints: [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.colors.textLight,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 40),

                          CustomButton(
                            label: 'Login',
                            isLoading: auth.isLoading,
                            onPressed: auth.isLoading ? null : _submit,
                          ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 20),

                          GestureDetector(
                            onTap: () => context.push(AppConstants.routeForgotPassword),
                            child: Text(
                              'Forgot Password',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                          SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go(AppConstants.routeRegister),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
