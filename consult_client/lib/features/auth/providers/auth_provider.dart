import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      final session = _supabase.auth.currentSession;
      final currentUser = _supabase.auth.currentUser;

      if (session != null && currentUser != null) {
        await _fetchAndSetUserProfile(currentUser);
        _status = AuthStatus.authenticated;
      } else {
        // Check cached local user fallback
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

      // Listen to auth state changes from Supabase
      _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? newSession = data.session;

        if (event == AuthChangeEvent.signedIn && newSession != null) {
          await _fetchAndSetUserProfile(newSession.user);
          _status = AuthStatus.authenticated;
          notifyListeners();
        } else if (event == AuthChangeEvent.signedOut) {
          _user = null;
          _status = AuthStatus.unauthenticated;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(AppConstants.keyUserData);
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _fetchAndSetUserProfile(User sbUser) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', sbUser.id)
          .maybeSingle();

      if (res != null) {
        _user = UserModel.fromJson(res);
      } else {
        // Fallback to metadata
        final meta = sbUser.userMetadata ?? {};
        _user = UserModel(
          id: sbUser.id,
          firstName: meta['first_name'] as String? ?? sbUser.email?.split('@').first ?? 'User',
          lastName: meta['last_name'] as String? ?? '',
          email: sbUser.email ?? '',
          phone: meta['phone'] as String? ?? sbUser.phone ?? '',
          createdAt: DateTime.tryParse(sbUser.createdAt) ?? DateTime.now(),
        );

        // Upsert into public.profiles
        await _supabase.from('profiles').upsert(_user!.toSupabaseMap());
      }
      await _saveUser();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _user = UserModel(
        id: sbUser.id,
        firstName: sbUser.email?.split('@').first ?? 'User',
        lastName: '',
        email: sbUser.email ?? '',
        phone: '',
        createdAt: DateTime.now(),
      );
    }
  }

  /// Real Supabase login
  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        await _fetchAndSetUserProfile(user);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Unable to sign in. Please try again.';
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Real Supabase registration
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
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'role': 'client',
        },
      );

      final user = response.user;
      if (user != null) {
        _user = UserModel(
          id: user.id,
          firstName: firstName,
          lastName: lastName,
          email: email.trim(),
          phone: phone,
          createdAt: DateTime.now(),
        );

        // If session exists (email confirmation disabled or auto-confirmed)
        if (response.session != null) {
          await _saveUser();
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }

        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Sign up failed. Please try again.';
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Sign up error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Real Supabase OTP verify
  Future<bool> verifyOtp(String otp, {String? email}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetEmail = email ?? _user?.email;
      if (targetEmail != null && targetEmail.isNotEmpty) {
        final response = await _supabase.auth.verifyOTP(
          type: OtpType.signup,
          token: otp,
          email: targetEmail,
        );

        if (response.user != null) {
          await _fetchAndSetUserProfile(response.user!);
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
      }

      // If already logged in locally
      if (_user != null) {
        await _saveUser();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Invalid OTP. Please try again.';
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Invalid verification code.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword({required String otp, required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
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

    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', _user!.id);
      }
    } catch (e) {
      debugPrint('Error updating profile in Supabase: $e');
    }

    await _saveUser();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
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
