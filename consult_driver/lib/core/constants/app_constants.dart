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
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVsa3NqY2l0ZW5seHR2eHd2a3R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2MDE0OTgsImV4cCI6MjEwMTE3NzQ5OH0.cKWA1RdL99z9IAYHkIeu6W0WxY6Sfk5PiRpJVTmvmtM';

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
