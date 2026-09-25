import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/motion.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/tap_target.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../widgets/auth_sheet_layout.dart';
import '../widgets/google_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }

    final nameParts = _nameCtrl.text.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final email = _emailCtrl.text.trim();

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      firstName: firstName,
      lastName: lastName.isEmpty ? 'User' : lastName,
      email: email,
      phone: '',
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      context.go(
        '${AppConstants.routeOtp}?email=${Uri.encodeComponent(email)}',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Registration failed. Please try again.',
          ),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  static const double _pillRadius = 30;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthSheetLayout(
          sheetHeight: 0.76,
          onBack: () => context.go(AppConstants.routeOnboarding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'Create '),
                      TextSpan(
                        text: 'New Account',
                        style: TextStyle(color: context.colors.accent),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ).motionAware(context).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                SizedBox(height: 8),

                Text(
                      'Book, track and insure your\nvehicle transport in minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.colors.textSecondary,
                        height: 1.5,
                      ),
                    )
                    .motionAware(context, delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 28),

                CustomTextField(
                      hint: 'Enter Your Name',
                      controller: _nameCtrl,
                      validator: AppValidators.validateName,
                      autofillHints: [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      borderRadius: _pillRadius,
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    )
                    .motionAware(context, delay: 150.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 16),

                CustomTextField(
                      hint: 'Enter Your Email',
                      controller: _emailCtrl,
                      validator: AppValidators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      borderRadius: _pillRadius,
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    )
                    .motionAware(context, delay: 200.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 16),

                CustomTextField(
                      hint: 'Create a Password',
                      controller: _passwordCtrl,
                      validator: AppValidators.validatePassword,
                      obscureText: _obscurePass,
                      autofillHints: [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      borderRadius: _pillRadius,
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: context.colors.textLight,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    )
                    .motionAware(context, delay: 250.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 20),

                // Terms checkbox
                Semantics(
                  checked: _agreedToTerms,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: 200.ms,
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: _agreedToTerms
                                ? context.colors.accentGradient
                                : null,
                            color: _agreedToTerms
                                ? null
                                : context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: _agreedToTerms
                                ? null
                                : Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                            boxShadow: _agreedToTerms
                                ? [
                                    BoxShadow(
                                      color: context.colors.accent.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          child: _agreedToTerms
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.black,
                                )
                              : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Agree with ',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: context.colors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).motionAware(context, delay: 300.ms).fadeIn(duration: 400.ms),

                SizedBox(height: 24),

                GlowButton(
                      label: 'Sign Up',
                      isLoading: auth.isLoading,
                      onPressed: auth.isLoading ? null : _submit,
                    )
                    .motionAware(context, delay: 350.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        endIndent: 16,
                      ),
                    ),
                    Text(
                      'or sign up with',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        indent: 16,
                      ),
                    ),
                  ],
                ).motionAware(context, delay: 400.ms).fadeIn(duration: 400.ms),

                SizedBox(height: 20),

                // Social buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      semanticLabel: 'Sign up with Apple',
                      onTap: () {},
                      child: Icon(
                        Icons.apple_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 20),
                    _SocialButton(
                      semanticLabel: 'Sign up with Google',
                      onTap: () {},
                      child: GoogleLogo(size: 24),
                    ),
                  ],
                ).motionAware(context, delay: 450.ms).fadeIn(duration: 400.ms),

                SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TapTarget(
                      onTap: () => context.go(AppConstants.routeLogin),
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: context.colors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).motionAware(context, delay: 500.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Frosted glass circle holding a sign-in provider's logo.
class _SocialButton extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback onTap;

  const _SocialButton({
    required this.child,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          width: 58,
          height: 58,
          radius: 29,
          blur: true,
          child: Center(child: child),
        ),
      ),
    );
  }
}
