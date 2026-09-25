import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(Duration(milliseconds: 1500)); // Mock
    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(gradient: context.colors.heroGradient),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => context.go(AppConstants.routeLogin),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  SizedBox(height: 32),

                  Container(
                        padding: EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _emailSent
                            ? _SuccessView(email: _emailCtrl.text)
                            : _FormView(
                                formKey: _formKey,
                                emailCtrl: _emailCtrl,
                                isLoading: _isLoading,
                                onSubmit: _submit,
                              ),
                      )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.08),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Enter the email associated with your account and we'll send instructions to reset your password.",
            style: TextStyle(
              fontSize: 14,
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          CustomTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: emailCtrl,
            validator: AppValidators.validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          SizedBox(height: 24),
          CustomButton(
            label: 'Send Reset Link',
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
            icon: Icon(Icons.send_rounded, color: Colors.black, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.colors.successLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: context.colors.success,
            size: 36,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        SizedBox(height: 16),
        Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'We sent a password reset link to\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.textSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 28),
        CustomButton(
          label: 'Back to Sign In',
          onPressed: () => context.go(AppConstants.routeLogin),
          isOutlined: true,
        ),
      ],
    );
  }
}
