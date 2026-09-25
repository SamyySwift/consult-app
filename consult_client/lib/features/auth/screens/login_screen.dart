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

  static const double _curveHeight = 70;
  static const double _pillRadius = 30;
  // Fractions of screen height.
  static const double _sheetHeight = 0.62;
  static const double _heroHeight = 0.55;
  static const double _heroOverlap = _heroHeight - (1 - _sheetHeight);

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
        final screen = MediaQuery.sizeOf(context);
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        final bodyHeight = screen.height - keyboard;
        final topInset = MediaQuery.paddingOf(context).top;

        return Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            children: [
              Column(
                children: [
                  // Hero image, anchored to the top of the sheet so it slides
                  // up with the form when the keyboard opens.
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -screen.height * _heroOverlap,
                          height: screen.height * _heroHeight,
                          child: Image.network(
                            AppConstants.heroImageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment(0.15, 0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom sheet form with a curved top edge. It keeps its full
                  // height until the keyboard eats into the empty space below
                  // the form, then pushes the hero up.
                  ClipPath(
                    clipper: _CurvedTopClipper(curveHeight: _curveHeight),
                    child: Container(
                      color: context.colors.surface,
                      constraints: BoxConstraints(
                        minHeight: (screen.height * _sheetHeight - keyboard)
                            .clamp(0, double.infinity),
                        maxHeight: bodyHeight - topInset,
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          _curveHeight + 12,
                          24,
                          32,
                        ),
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
                                          style: TextStyle(
                                            color: context.colors.accent,
                                          ),
                                        ),
                                        TextSpan(text: 'Our Care.'),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1),

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
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
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
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: context.colors.textLight,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
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
                                  onTap: () => context.push(
                                    AppConstants.routeForgotPassword,
                                  ),
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

                              CustomButton(
                                    label: 'Login',
                                    isLoading: auth.isLoading,
                                    onPressed: auth.isLoading ? null : _submit,
                                    borderRadius: _pillRadius,
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
                                    onTap: () =>
                                        context.go(AppConstants.routeRegister),
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
                      ),
                    ),
                  ),
                ],
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
            ],
          ),
        );
      },
    );
  }
}

/// Clips the top of the form sheet into a dome: low at both sides, peaking
/// in the middle.
class _CurvedTopClipper extends CustomClipper<Path> {
  final double curveHeight;

  const _CurvedTopClipper({required this.curveHeight});

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, curveHeight)
      ..quadraticBezierTo(size.width / 2, -curveHeight, size.width, curveHeight)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_CurvedTopClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}
