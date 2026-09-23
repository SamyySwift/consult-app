import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

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

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? 'Driver',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      licenseNumber: json['licenseNumber'] ?? json['license_number'],
      vehicleType: json['vehicleType'] ?? json['vehicle_type'],
      vehiclePlate: json['vehiclePlate'] ?? json['vehicle_plate'],
      isOnline: json['isOnline'] == true || json['is_online'] == true,
      isVerified: json['isVerified'] == true || json['is_verified'] == true,
      rating: ((json['rating'] ?? 5.0) as num).toDouble(),
      totalJobs: json['totalJobs'] ?? json['total_trips'] ?? 0,
    );
  }

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

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _initSession();
  }

  Future<void> _initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiClient.instance.init();
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('driver_logged_in') ?? false;

      if (isLoggedIn) {
        final savedId = prefs.getString('driver_id') ?? AppConstants.mockDriverId;
        _driver = DriverModel(
          id: savedId,
          firstName: prefs.getString('driver_first_name') ?? 'Adewale',
          lastName: prefs.getString('driver_last_name') ?? 'Okonkwo',
          email: prefs.getString('driver_email') ?? 'driver@carpitalconsult.com',
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
    } catch (e) {
      debugPrint('Driver session init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post('/api/driver/login', {
        'email': email.trim(),
        'password': password,
      });

      if (res.isSuccess && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        await ApiClient.instance.setToken(token);

        if (data['driver'] != null) {
          _driver = DriverModel.fromJson(data['driver'] as Map<String, dynamic>);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_logged_in', true);
        if (_driver != null) {
          await prefs.setString('driver_id', _driver!.id);
          await prefs.setString('driver_email', _driver!.email);
          await prefs.setString('driver_first_name', _driver!.firstName);
          await prefs.setString('driver_last_name', _driver!.lastName);
          await prefs.setString('driver_phone', _driver!.phone);
          if (_driver!.licenseNumber != null) {
            await prefs.setString('driver_license', _driver!.licenseNumber!);
          }
          if (_driver!.vehiclePlate != null) {
            await prefs.setString('driver_plate', _driver!.vehiclePlate!);
          }
        }

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.errorMessage ?? 'Invalid email or password';
      }
    } catch (e) {
      debugPrint('Driver login error: $e');
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
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post('/api/driver/register', {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'licenseNumber': licenseNumber ?? '',
        'vehicleType': vehicleType ?? 'Tow Truck',
        'vehiclePlate': vehiclePlate ?? '',
      });

      if (res.isSuccess && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        await ApiClient.instance.setToken(token);

        if (data['driver'] != null) {
          _driver = DriverModel.fromJson(data['driver'] as Map<String, dynamic>);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_logged_in', true);
        if (_driver != null) {
          await prefs.setString('driver_id', _driver!.id);
          await prefs.setString('driver_email', _driver!.email);
          await prefs.setString('driver_first_name', firstName);
          await prefs.setString('driver_last_name', lastName);
          await prefs.setString('driver_phone', phone);
        }

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.errorMessage ?? 'Registration failed';
      }
    } catch (e) {
      debugPrint('Driver register error: $e');
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    final success = otp.length == 6;
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await ApiClient.instance.setToken(null);
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
      ApiClient.instance.post('/api/driver/status', {
        'driverId': _driver!.id,
        'isOnline': newStatus,
      });
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

    final prefs = await SharedPreferences.getInstance();
    if (firstName != null) await prefs.setString('driver_first_name', firstName);
    if (lastName != null) await prefs.setString('driver_last_name', lastName);
    if (phone != null) await prefs.setString('driver_phone', phone);
  }
}
