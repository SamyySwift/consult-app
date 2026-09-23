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
          content: Text(auth.errorMessage ?? 'Registration failed. Please try again.'),
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
          body: SafeArea(
            child: Column(
              children: [
                // Custom App bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.go(AppConstants.routeLogin),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      Text(
                        'Create New Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'Name',
                            hint: 'Please input your name',
                            controller: _nameCtrl,
                            validator: AppValidators.validateName,
                            textInputAction: TextInputAction.next,
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 24),

                          CustomTextField(
                            label: 'Email',
                            hint: 'example@gmail.com',
                            controller: _emailCtrl,
                            validator: AppValidators.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 24),

                          CustomTextField(
                            label: 'Password',
                            hint: '********',
                            controller: _passwordCtrl,
                            validator: AppValidators.validatePassword,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: context.colors.textLight,
                              ),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 32),

                          // Terms checkbox
                          GestureDetector(
                            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _agreedToTerms ? Colors.white : context.colors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: _agreedToTerms
                                      ? Icon(Icons.check_rounded, size: 16, color: context.colors.accent)
                                      : null,
                                ),
                                SizedBox(width: 12),
                                Text.rich(
                                  TextSpan(
                                    text: 'Agree with ',
                                    style: TextStyle(
                                        fontSize: 14, color: context.colors.textSecondary),
                                    children: [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 32),

                          CustomButton(
                            label: 'Sign Up',
                            isLoading: auth.isLoading,
                            onPressed: auth.isLoading ? null : _submit,
                          ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 48),

                          Row(
                            children: [
                              Expanded(child: Divider(color: context.colors.border, endIndent: 16)),
                              Text(
                                'or sign up with',
                                style: TextStyle(color: context.colors.textLight.withValues(alpha: 0.7), fontSize: 13),
                              ),
                              Expanded(child: Divider(color: context.colors.border, indent: 16)),
                            ],
                          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                          SizedBox(height: 32),

                          // Social buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialIconButton(icon: Icons.apple_rounded, onTap: () {}),
                              SizedBox(width: 24),
                              _SocialIconButton(icon: Icons.g_mobiledata_rounded, onTap: () {}, iconColor: Colors.green),
                              SizedBox(width: 24),
                              _SocialIconButton(icon: Icons.facebook_rounded, onTap: () {}, iconColor: Colors.blue),
                            ],
                          ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                          SizedBox(height: 48),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => context.go(AppConstants.routeLogin),
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _SocialIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
