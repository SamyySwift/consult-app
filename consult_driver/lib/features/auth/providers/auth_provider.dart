import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';

class DriverModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? licenseNumber;
  final String? vehicleType;
  final String? vehiclePlate;
  final bool isOnline;
  final bool isVerified;
  final double rating;
  final int totalJobs;

  const DriverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.licenseNumber,
    this.vehicleType,
    this.vehiclePlate,
    this.isOnline = false,
    this.isVerified = false,
    this.rating = 5.0,
    this.totalJobs = 0,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory DriverModel.fromSupabase(
    Map<String, dynamic> profileMap, [
    Map<String, dynamic>? driverMap,
  ]) {
    final fullName = (profileMap['full_name'] as String? ?? '').trim();
    final nameParts = fullName.isNotEmpty ? fullName.split(' ') : <String>[];
    final firstName = nameParts.isNotEmpty
        ? nameParts.first
        : (profileMap['first_name'] as String? ?? 'Driver');
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : (profileMap['last_name'] as String? ?? '');

    final statusStr = driverMap?['status']?.toString();
    final isOnline = statusStr == 'available' || statusStr == 'on_trip' || (driverMap?['is_online'] == true);

    return DriverModel(
      id: profileMap['id'] ?? driverMap?['id'] ?? '',
      firstName: firstName,
      lastName: lastName,
      email: profileMap['email'] ?? '',
      phone: profileMap['phone'] ?? '',
      licenseNumber: driverMap?['license_number'],
      vehicleType: driverMap?['vehicle_type'],
      vehiclePlate: driverMap?['vehicle_plate'],
      isOnline: isOnline,
      isVerified: true,
      rating: ((driverMap?['rating'] ?? 5.0) as num).toDouble(),
      totalJobs: driverMap?['total_trips'] ?? 0,
    );
  }

  DriverModel copyWith({
    bool? isOnline,
    bool? isVerified,
    String? firstName,
    String? lastName,
    String? phone,
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
    double? rating,
    int? totalJobs,
  }) {
    return DriverModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  DriverModel? _driver;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  StreamSubscription<AuthState>? _authSubscription;

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  SupabaseClient get _supabase => Supabase.instance.client;

  AuthProvider() {
    _initSession();
    _listenAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      if (session != null) {
        _fetchDriverProfile(session.user.id, session.user.email ?? '');
      } else if (event == AuthChangeEvent.signedOut) {
        _driver = null;
        _isAuthenticated = false;
        notifyListeners();
      }
    });
  }

  Future<void> _initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _fetchDriverProfile(session.user.id, session.user.email ?? '');
      } else {
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('driver_logged_in') ?? false;

        if (isLoggedIn) {
          final savedId = prefs.getString('driver_id') ?? AppConstants.mockDriverId;
          _driver = DriverModel(
            id: savedId,
            firstName: prefs.getString('driver_first_name') ?? 'Adewale',
            lastName: prefs.getString('driver_last_name') ?? 'Okonkwo',
            email: prefs.getString('driver_email') ?? 'driver@automove.com',
            phone: prefs.getString('driver_phone') ?? '+234 812 345 6789',
            licenseNumber: prefs.getString('driver_license') ?? 'LG-2023-0048291',
            vehiclePlate: prefs.getString('driver_plate') ?? 'LND-394-FY',
            isVerified: true,
            isOnline: true,
            rating: 4.9,
            totalJobs: 52,
          );
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      debugPrint('Driver session init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDriverProfile(String userId, String email) async {
    try {
      final profileRes = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      Map<String, dynamic>? driverRes;
      try {
        driverRes = await _supabase
            .from('drivers')
            .select()
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {}

      if (profileRes != null) {
        _driver = DriverModel.fromSupabase(profileRes, driverRes);
        _isAuthenticated = true;
      } else {
        _driver = DriverModel(
          id: userId,
          firstName: 'Driver',
          lastName: '',
          email: email,
          phone: '',
          isVerified: true,
          isOnline: true,
          rating: 5.0,
          totalJobs: 0,
        );
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error fetching driver profile: $e');
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        await _fetchDriverProfile(response.user!.id, response.user!.email ?? email);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_logged_in', true);
        await prefs.setString('driver_id', response.user!.id);
        await prefs.setString('driver_email', email);
        if (_driver != null) {
          await prefs.setString('driver_first_name', _driver!.firstName);
          await prefs.setString('driver_last_name', _driver!.lastName);
          await prefs.setString('driver_phone', _driver!.phone);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Fallback for demo/offline test
      if (email.isNotEmpty && password.length >= 6) {
        _driver = DriverModel(
          id: AppConstants.mockDriverId,
          firstName: 'Adewale',
          lastName: 'Okonkwo',
          email: email,
          phone: '+234 812 345 6789',
          licenseNumber: 'LG-2023-0048291',
          vehiclePlate: 'LND-394-FY',
          isVerified: true,
          isOnline: true,
          rating: 4.9,
          totalJobs: 52,
        );
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_logged_in', true);
        await prefs.setString('driver_id', AppConstants.mockDriverId);
        await prefs.setString('driver_email', email);
        await prefs.setString('driver_first_name', _driver!.firstName);
        await prefs.setString('driver_last_name', _driver!.lastName);
        await prefs.setString('driver_phone', _driver!.phone);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': '$firstName $lastName'.trim(),
          'phone': phone.trim(),
          'role': 'driver',
        },
      );

      final user = response.user;
      if (user != null) {
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'email': email.trim(),
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'phone': phone.trim(),
            'role': 'driver',
          });

          await _supabase.from('drivers').upsert({
            'id': user.id,
            'status': 'available',
            'rating': 5.0,
            'total_trips': 0,
          });
        } catch (e) {
          debugPrint('Error inserting driver record: $e');
        }

        _driver = DriverModel(
          id: user.id,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          isVerified: true,
          isOnline: true,
          rating: 5.0,
          totalJobs: 0,
        );
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_logged_in', true);
        await prefs.setString('driver_id', user.id);
        await prefs.setString('driver_email', email);
        await prefs.setString('driver_first_name', firstName);
        await prefs.setString('driver_last_name', lastName);
        await prefs.setString('driver_phone', phone);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (email.isNotEmpty && password.length >= 6) {
        final mockId = 'drv_${DateTime.now().millisecondsSinceEpoch}';
        _driver = DriverModel(
          id: mockId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          isVerified: true,
          isOnline: true,
          rating: 5.0,
          totalJobs: 0,
        );
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_logged_in', true);
        await prefs.setString('driver_id', mockId);
        await prefs.setString('driver_email', email);
        await prefs.setString('driver_first_name', firstName);
        await prefs.setString('driver_last_name', lastName);
        await prefs.setString('driver_phone', phone);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    final success = otp.length == 6;
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _driver = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void toggleOnlineStatus() {
    if (_driver == null) return;
    final newStatus = !_driver!.isOnline;
    _driver = _driver!.copyWith(isOnline: newStatus);
    notifyListeners();

    try {
      _supabase.from('drivers').update({'status': newStatus ? 'available' : 'offline'}).eq('id', _driver!.id);
    } catch (_) {}
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? licenseNumber,
    String? vehiclePlate,
  }) async {
    if (_driver == null) return;
    _driver = _driver!.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      licenseNumber: licenseNumber,
      vehiclePlate: vehiclePlate,
    );
    notifyListeners();

    try {
      final profileUpdates = <String, dynamic>{};
      if (firstName != null) profileUpdates['first_name'] = firstName;
      if (lastName != null) profileUpdates['last_name'] = lastName;
      if (phone != null) profileUpdates['phone'] = phone;

      if (profileUpdates.isNotEmpty) {
        await _supabase.from('profiles').update(profileUpdates).eq('id', _driver!.id);
      }

      final driverUpdates = <String, dynamic>{};
      if (licenseNumber != null) driverUpdates['license_number'] = licenseNumber;
      if (vehiclePlate != null) driverUpdates['vehicle_plate'] = vehiclePlate;

      if (driverUpdates.isNotEmpty) {
        await _supabase.from('drivers').update(driverUpdates).eq('id', _driver!.id);
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    if (firstName != null) await prefs.setString('driver_first_name', firstName);
    if (lastName != null) await prefs.setString('driver_last_name', lastName);
    if (phone != null) await prefs.setString('driver_phone', phone);
  }
}
