import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String completeProfile = '/complete-profile';

  // Main shell
  static const String dashboard = '/dashboard';
  static const String jobBoard = '/jobs';
  static const String activeJob = '/jobs/active';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
}

class AppConstants {
  static const String appName = 'Carpital Consult Driver';
  static const String appVersion = '1.0.0';

  // TODO: confirm this placeholder address before release (same as client).
  static const String supportEmail = 'support@carpitalconsult.com';

  /// Highway freight-truck hero photo shown behind the dashboard and auth screens.
  static const String heroImageUrl =
      'https://images.unsplash.com/photo-1519003722824-194d4455a60c?q=80&w=2000&auto=format&fit=crop';

  // Supabase Configuration
  static const String supabaseUrl = 'https://ulksjcitenlxtvxwvktw.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Railway API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://carpitalconsult.com';

  // Storage Keys
  static const String keyUserData = 'driver_user_data';
  static const String keyAuthToken = 'driver_auth_token';

  // Insurance flat fee per booking (₦)
  static const double insuranceFee = 15000;

  // Commission percentage taken from job
  static const double commissionRate = 0.10; // 10%

  // OTP timeout seconds
  static const int otpTimeout = 120;

  // Mock driver ID
  static const String mockDriverId = 'drv_001';
}
