class AppValidators {
  AppValidators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    if (value.trim().length < 2) return 'Must be at least 2 characters';
    return null;
  }

  static String? validateRequired(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? validateVin(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    if (value.trim().length != 17) return 'VIN must be exactly 17 characters';
    return null;
  }

  static String? validateYear(String? value) {
    if (value == null || value.trim().isEmpty) return 'Year is required';
    final year = int.tryParse(value.trim());
    if (year == null) return 'Enter a valid year';
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) return 'Enter a valid vehicle year';
    return null;
  }
}
