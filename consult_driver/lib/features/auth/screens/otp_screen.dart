import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';
import '../providers/auth_provider.dart';

class DriverOtpScreen extends StatefulWidget {
  final String? email;

  const DriverOtpScreen({
    super.key,
    this.email,
  });

  @override
  State<DriverOtpScreen> createState() => _DriverOtpScreenState();
}

class _DriverOtpScreenState extends State<DriverOtpScreen> {
  String _otp = '';
  int _secondsLeft = AppConstants.otpTimeout;
  Timer? _timer;
  bool _canResend = false;

  String _getDestination(AuthProvider auth) {
    if (widget.email != null && widget.email!.trim().isNotEmpty) {
      return widget.email!.trim();
    }
    if (auth.pendingEmail != null && auth.pendingEmail!.trim().isNotEmpty) {
      return auth.pendingEmail!.trim();
    }
    if (auth.driver?.email != null && auth.driver!.email.trim().isNotEmpty) {
      return auth.driver!.email.trim();
    }
    return 'your email address';
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
    _secondsLeft = AppConstants.otpTimeout;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    final auth = context.read<AuthProvider>();
    final destination = _getDestination(auth);

    final success = await auth.verifyOtp(
      _otp,
      email: destination.contains('@') ? destination : null,
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Invalid verification code',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: DriverColors.error,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    final auth = context.read<AuthProvider>();
    final destination = _getDestination(auth);

    if (!destination.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid email found to resend code to.'),
          backgroundColor: DriverColors.error,
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
          backgroundColor: DriverColors.accent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to resend code'),
          backgroundColor: DriverColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1.2),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: DriverColors.accent, width: 2),
        color: DriverColors.accent.withValues(alpha: 0.08),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: DriverColors.accent.withValues(alpha: 0.5), width: 1.5),
        color: const Color(0xFF1E1E1E),
      ),
    );

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final destination = _getDestination(auth);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.go(AppRoutes.login),
            ),
            title: const Text(
              'Security Verification',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Hero Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: DriverColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: DriverColors.accent.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 38,
                      color: DriverColors.accent,
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  const Text(
                    'Verify Your Driver Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 10),

                  Text.rich(
                    TextSpan(
                      text: 'We have dispatched a 6-digit security code to\n',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 36),

                  // Pin Input
                  Pinput(
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    autofocus: true,
                    onChanged: (v) => setState(() => _otp = v),
                    onCompleted: (_) => _verify(),
                    keyboardType: TextInputType.number,
                  ).animate(delay: 250.ms).fadeIn().scale(),

                  const SizedBox(height: 32),

                  // Verify Button
                  DriverButton(
                    label: 'Verify & Enter Portal',
                    onPressed: (_otp.length == 6 && !auth.isLoading) ? _verify : null,
                    isLoading: auth.isLoading,
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 28),

                  // Resend Timer / Action
                  if (_canResend) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive the code? ",
                          style: TextStyle(color: Color(0xFF777777), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: auth.isLoading ? null : _resendCode,
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: DriverColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Color(0xFF666666),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Resend code in ${_secondsLeft}s',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
