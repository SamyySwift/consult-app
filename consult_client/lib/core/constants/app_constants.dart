class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AutoMove';
  static const String appTagline = 'Your vehicle, safely delivered.';

  // Routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeOtp = '/otp';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeHome = '/home';
  static const String routeBookings = '/bookings';
  static const String routeTrack = '/track';
  static const String routeGarage = '/garage';
  static const String routePayments = '/payments';
  static const String routeProfile = '/profile';
  static const String routeBookingNew = '/booking/new';
  static const String routeNotifications = '/notifications';

  // Supabase Configuration
  static const String supabaseUrl = 'https://ulksjcitenlxtvxwvktw.supabase.co';
  static const String supabaseAnonKey =
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Paystack
  // TODO: Replace with your live Paystack public key
  static const String paystackPublicKey = 'pk_test_xxxxxxxxxxxxxxxxxxxx';

  // Pricing (NGN)
  static const double standardServicePrice = 75000;
  static const double expressServicePrice = 120000;
  static const double whiteGloveServicePrice = 200000;
  static const double enclosedTransportAddon = 30000;
  static const double insuranceFee = 15000;

  // Storage Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'user_data';

  // OTP Timeout (seconds)
  static const int otpTimeoutSeconds = 60;
}
