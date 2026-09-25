import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/custom_text_field.dart';
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

  static const double _pillRadius = 30;

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
        return AuthSheetLayout(
          sheetHeight: 0.62,
          onBack: () => context.go(AppConstants.routeOnboarding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: 'Your Car. ',
                        style: TextStyle(color: context.colors.accent),
                      ),
                      TextSpan(text: 'Our Care.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                SizedBox(height: 8),

                Text(
                      'Vetted carriers, live GPS tracking\nand fully insured transit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.colors.textSecondary,
                        height: 1.5,
                      ),
                    )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 32),

                CustomTextField(
                      hint: 'Enter Your Email',
                      controller: _emailController,
                      validator: AppValidators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      borderRadius: _pillRadius,
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 16),

                CustomTextField(
                      hint: 'Enter Your Password',
                      controller: _passwordController,
                      validator: AppValidators.validatePassword,
                      obscureText: _obscurePassword,
                      autofillHints: [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      borderRadius: _pillRadius,
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: context.colors.textLight,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push(AppConstants.routeForgotPassword),
                    child: Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: context.colors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

                SizedBox(height: 28),

                GlowButton(
                      label: 'Login',
                      isLoading: auth.isLoading,
                      onPressed: auth.isLoading ? null : _submit,
                    )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 24),

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
                          color: context.colors.accent,
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
        );
      },
    );
  }
}
