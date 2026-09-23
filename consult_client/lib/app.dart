import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/home/home_screen.dart';
import 'features/booking/screens/booking_wizard.dart';
import 'features/tracking/screens/tracking_screen.dart';
import 'features/payments/screens/payment_history_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/my_bookings_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/vehicles/screens/vehicle_garage_screen.dart';

final _router = GoRouter(
  initialLocation: AppConstants.routeSplash,
  routes: [
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (context, state) => Theme(
        data: AppTheme.darkTheme,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: AppConstants.routeOnboarding,
      builder: (context, state) => Theme(
        data: AppTheme.darkTheme,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppConstants.routeLogin,
      builder: (context, state) => Theme(
        data: AppTheme.darkTheme,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (context, state) => Theme(
        data: AppTheme.darkTheme,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: AppConstants.routeOtp,
      builder: (context, state) => Theme(
        data: AppTheme.darkTheme,
        child: OtpScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: AppConstants.routeForgotPassword,
      builder: (context, state) => Theme(
        data: AppTheme.darkTheme,
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: AppConstants.routeBookingNew,
      builder: (context, state) => const BookingWizard(),
    ),
    GoRoute(
      path: AppConstants.routeNotifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppConstants.routeHome,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppConstants.routeBookings,
          builder: (context, state) => const MyBookingsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeTrack,
          builder: (context, state) => const TrackingScreen(),
        ),
        GoRoute(
          path: AppConstants.routePayments,
          builder: (context, state) => const PaymentHistoryScreen(),
        ),
        GoRoute(
          path: AppConstants.routeGarage,
          builder: (context, state) => const VehicleGarageScreen(),
        ),
        GoRoute(
          path: AppConstants.routeProfile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class AutoMoveApp extends StatelessWidget {
  const AutoMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
