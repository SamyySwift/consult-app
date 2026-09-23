class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';

  // Main shell
  static const String dashboard = '/dashboard';
  static const String jobBoard = '/jobs';
  static const String activeJob = '/jobs/active';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
}

class AppConstants {
  static const String appName = 'AutoMove Driver';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://ulksjcitenlxtvxwvktw.supabase.co';
  static const String supabaseAnonKey =
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

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
