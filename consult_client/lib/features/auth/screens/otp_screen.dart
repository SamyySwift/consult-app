import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';


class OtpScreen extends StatefulWidget {
  final String? email;
  final String? phone;

  const OtpScreen({
    super.key,
    this.email,
    this.phone,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  int _secondsLeft = AppConstants.otpTimeoutSeconds;
  Timer? _timer;
  bool _canResend = false;

  String _getDestination(AuthProvider auth) {
    if (widget.email != null && widget.email!.trim().isNotEmpty) {
      return widget.email!.trim();
    }
    if (auth.user?.email != null && auth.user!.email.trim().isNotEmpty) {
      return auth.user!.email.trim();
    }
    if (widget.phone != null && widget.phone!.trim().isNotEmpty) {
      return widget.phone!.trim();
    }
    return 'your email';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = AppConstants.otpTimeoutSeconds;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    final auth = context.read<AuthProvider>();
    final destination = _getDestination(auth);
    final isEmail = destination.contains('@');

    final success = await auth.verifyOtp(
      _otp,
      email: isEmail ? destination : null,
    );
    if (!mounted) return;
    if (success) {
      context.go(AppConstants.routeHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Invalid verification code'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    final auth = context.read<AuthProvider>();
    final destination = _getDestination(auth);

    if (!destination.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No valid email address found to resend code to.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    _startTimer();
    final success = await auth.resendOtp(destination);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh 6-digit code has been sent to $destination'),
          backgroundColor: context.colors.accent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to resend code'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border, width: 1),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: context.colors.accent, width: 2),
        color: context.colors.accent.withValues(alpha: 0.05),
      ),
    );

    final filledTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.4), width: 1.5),
        color: context.colors.accent.withValues(alpha: 0.06),
      ),
    );

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(gradient: context.colors.heroGradient),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12),
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => context.go(AppConstants.routeRegister),
                      ),
                      SizedBox(height: 16),

                      // Verify illustration
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 40,
                            color: Colors.white,
                          ),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                      ),

                      SizedBox(height: 32),

                      Center(
                        child: Container(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Verify Your Email',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                ),
                              ),

                              SizedBox(height: 8),

                              Text.rich(
                                TextSpan(
                                  text: 'We sent a 6-digit code to\n',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.colors.textSecondary,
                                    height: 1.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _getDestination(auth),
                                      style: TextStyle(
                                        color: context.colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 32),

                              Pinput(
                                length: 6,
                                defaultPinTheme: defaultTheme,
                                focusedPinTheme: focusedTheme,
                                submittedPinTheme: filledTheme,
                                onChanged: (v) => setState(() => _otp = v),
                                onCompleted: (_) => _verify(),
                                keyboardType: TextInputType.number,
                              ),

                              SizedBox(height: 28),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: (_otp.length == 6 && !auth.isLoading) ? _verify : null,
                                  child: auth.isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text('Verify Code'),
                                ),
                              ),

                              SizedBox(height: 20),

                              if (_canResend)
                                TextButton.icon(
                                  onPressed: auth.isLoading ? null : _resendCode,
                                  icon: Icon(Icons.refresh_rounded, size: 18),
                                  label: Text('Resend Code'),
                                )
                              else
                                RichText(
                                  text: TextSpan(
                                    text: "Resend code in ",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.textSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${_secondsLeft}s',
                                        style: TextStyle(
                                          color: context.colors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: 12),

                              TextButton(
                                onPressed: () => context.go(AppConstants.routeLogin),
                                child: Text(
                                  'Back to Sign In',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
                      ),
                    ],
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
