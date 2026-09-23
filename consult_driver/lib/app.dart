import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/driver_theme.dart';
import 'core/constants/app_constants.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/jobs/screens/job_board_screen.dart';
import 'features/jobs/screens/active_job_screen.dart';
import 'features/earnings/screens/earnings_screen.dart';
import 'features/profile/screens/profile_screen.dart';

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) => DriverOtpScreen(
        email: state.uri.queryParameters['email'],
      ),
    ),
    GoRoute(
      path: AppRoutes.activeJob,
      builder: (context, state) => const ActiveJobScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.jobBoard,
          builder: (context, state) => const JobBoardScreen(),
        ),
        GoRoute(
          path: AppRoutes.earnings,
          builder: (context, state) => const EarningsScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class CarpitalConsultDriverApp extends StatelessWidget {
  const CarpitalConsultDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: DriverTheme.lightTheme,
      darkTheme: DriverTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
