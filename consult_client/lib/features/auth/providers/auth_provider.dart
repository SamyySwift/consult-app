import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _api.init();

      if (_api.token != null && _api.token!.isNotEmpty) {
        // Fetch current profile from Railway backend
        final res = await _api.get('/api/auth/me');
        if (res.isSuccess && res.data is Map) {
          _user = UserModel.fromJson(res.data as Map<String, dynamic>);
          _status = AuthStatus.authenticated;
          await _saveUser();
        } else {
          // Token expired or server unreachable, fallback to cached user
          await _loadCachedUser();
        }
      } else {
        await _loadCachedUser();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.keyUserData);
    if (userData != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userData) as Map<String, dynamic>);
        _status = AuthStatus.authenticated;
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
  }

  /// Login via Railway API
  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/api/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      if (res.isSuccess && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        await _api.setToken(data['token'] as String?);
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _saveUser();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = res.errorMessage ?? 'Unable to sign in. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Registration via Railway API
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/api/auth/register', {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      });

      if (res.isSuccess) {
        _user = UserModel(
          id: (res.data is Map ? res.data['userId'] : null) ?? '',
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: email.trim(),
          phone: phone.trim(),
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = res.errorMessage ?? 'Sign up failed. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Sign up error: $e';
      notifyListeners();
      return false;
    }
  }

  /// OTP verification via Railway API
  Future<bool> verifyOtp(String otp, {String? email}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetEmail = (email != null && email.isNotEmpty) ? email.trim() : _user?.email;
      if (targetEmail == null || targetEmail.isEmpty) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'No email address found to verify.';
        notifyListeners();
        return false;
      }

      final res = await _api.post('/api/auth/verify-otp', {
        'email': targetEmail,
        'otp': otp.trim(),
      });

      if (res.isSuccess && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        await _api.setToken(data['token'] as String?);
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _saveUser();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = res.errorMessage ?? 'Invalid verification code.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Invalid verification code.';
      notifyListeners();
      return false;
    }
  }

  /// Resend Signup OTP via Railway API (triggers Resend)
  Future<bool> resendOtp(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/api/auth/resend-otp', {
        'email': email.trim(),
      });

      _status = AuthStatus.unauthenticated;
      if (res.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.errorMessage ?? 'Failed to resend code.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Failed to resend code: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({String? firstName, String? lastName, String? phone, String? avatarUrl}) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    await _saveUser();
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserData);
    await prefs.remove(AppConstants.keyAuthToken);
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _saveUser() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserData, jsonEncode(_user!.toJson()));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
