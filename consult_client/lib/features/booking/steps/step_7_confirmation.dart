import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/booking_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';

class Step7Confirmation extends StatelessWidget {
  const Step7Confirmation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        final lastBooking = prov.bookings.isNotEmpty ? prov.bookings.first : null;
        final bookingId = lastBooking?.id ?? 'BK------';

        return Scaffold(
          backgroundColor: context.colors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 32),

                  // Success animation
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: context.colors.successLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.success.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(Icons.check_circle_rounded, color: context.colors.success, size: 64),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 300.ms),

                  SizedBox(height: 28),

                  Text(
                    'Booking Confirmed! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
                  ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

                  SizedBox(height: 8),

                  Text(
                    'Your vehicle transport has been\nsuccessfully booked.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: context.colors.textSecondary, height: 1.5),
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

                  SizedBox(height: 32),

                  // Booking ID card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A1628), Color(0xFF1E3A5F)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Booking Reference',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        SizedBox(height: 8),
                        Text(
                          bookingId,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: bookingId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Booking ID copied!')),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                                SizedBox(width: 6),
                                Text('Copy ID', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                  SizedBox(height: 24),

                  // What happens next
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What happens next?",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                        ),
                        SizedBox(height: 16),
                        _NextStep(
                          number: '1',
                          title: 'Confirmation Email',
                          subtitle: 'A confirmation with details has been sent to your email',
                          icon: Icons.mail_rounded,
                          color: context.colors.info,
                        ),
                        SizedBox(height: 12),
                        _NextStep(
                          number: '2',
                          title: 'Driver Assigned',
                          subtitle: 'A driver will be assigned 24 hours before pickup',
                          icon: Icons.person_rounded,
                          color: context.colors.warning,
                        ),
                        SizedBox(height: 12),
                        _NextStep(
                          number: '3',
                          title: 'Pickup Day',
                          subtitle: 'Driver will call you 30 minutes before arrival',
                          icon: Icons.directions_car_rounded,
                          color: context.colors.accent,
                        ),
                        SizedBox(height: 12),
                        _NextStep(
                          number: '4',
                          title: 'Track in Real Time',
                          subtitle: 'Monitor your vehicle\'s journey live on the map',
                          icon: Icons.my_location_rounded,
                          color: context.colors.success,
                          isLast: true,
                        ),
                      ],
                    ),
                  ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                  SizedBox(height: 28),

                  CustomButton(
                    label: 'Track My Vehicle',
                    onPressed: () {
                      context.go(AppConstants.routeTrack);
                    },
                    icon: Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                  ).animate(delay: 700.ms).fadeIn(),

                  SizedBox(height: 12),

                  CustomButton.outlined(
                    label: 'Back to Home',
                    onPressed: () => context.go(AppConstants.routeHome),
                  ).animate(delay: 800.ms).fadeIn(),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NextStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLast;

  const _NextStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
              SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
