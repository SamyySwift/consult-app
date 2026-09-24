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
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? residentialAddress;
  final String? stateLga;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? ninNumber;
  final String? driverLicenseImage;
  final String? licenseNumber;
  final String? vehicleType;
  final String? vehiclePlate;
  final bool isOnline;
  final bool isVerified;
  final bool isProfileCompleted;
  final double rating;
  final int totalJobs;

  const DriverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.residentialAddress,
    this.stateLga,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.ninNumber,
    this.driverLicenseImage,
    this.licenseNumber,
    this.vehicleType,
    this.vehiclePlate,
    this.isOnline = false,
    this.isVerified = false,
    this.isProfileCompleted = false,
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
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      dateOfBirth: json['dateOfBirth'] ?? json['date_of_birth'],
      residentialAddress: json['residentialAddress'] ?? json['residential_address'],
      stateLga: json['stateLga'] ?? json['state_lga'],
      emergencyContactName: json['emergencyContactName'] ?? json['emergency_contact_name'],
      emergencyContactPhone: json['emergencyContactPhone'] ?? json['emergency_contact_phone'],
      emergencyContactRelationship:
          json['emergencyContactRelationship'] ?? json['emergency_contact_relationship'],
      ninNumber: json['ninNumber'] ?? json['nin_number'],
      driverLicenseImage: json['driverLicenseImage'] ?? json['driver_license_image'],
      licenseNumber: json['licenseNumber'] ?? json['license_number'],
      vehicleType: json['vehicleType'] ?? json['vehicle_type'],
      vehiclePlate: json['vehiclePlate'] ?? json['vehicle_plate'],
      isOnline: json['isOnline'] == true || json['is_online'] == true,
      isVerified: json['isVerified'] == true || json['is_verified'] == true,
      isProfileCompleted:
          json['isProfileCompleted'] == true || json['is_profile_completed'] == true,
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
      avatarUrl: profileMap['avatar_url'],
      dateOfBirth: profileMap['date_of_birth'],
      residentialAddress: profileMap['residential_address'],
      stateLga: profileMap['state_lga'],
      emergencyContactName: profileMap['emergency_contact_name'],
      emergencyContactPhone: profileMap['emergency_contact_phone'],
      emergencyContactRelationship: profileMap['emergency_contact_relationship'],
      ninNumber: profileMap['nin_number'],
      driverLicenseImage: profileMap['driver_license_image'],
      licenseNumber: driverMap?['license_number'],
      vehicleType: driverMap?['vehicle_type'],
      vehiclePlate: driverMap?['vehicle_plate'],
      isOnline: isOnline,
      isVerified: true,
      isProfileCompleted: profileMap['is_profile_completed'] == true,
      rating: ((driverMap?['rating'] ?? 5.0) as num).toDouble(),
      totalJobs: driverMap?['total_trips'] ?? 0,
    );
  }

  DriverModel copyWith({
    bool? isOnline,
    bool? isVerified,
    bool? isProfileCompleted,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? dateOfBirth,
    String? residentialAddress,
    String? stateLga,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? ninNumber,
    String? driverLicenseImage,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      stateLga: stateLga ?? this.stateLga,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      ninNumber: ninNumber ?? this.ninNumber,
      driverLicenseImage: driverLicenseImage ?? this.driverLicenseImage,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
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
  String? _pendingEmail;
  bool _needsOtp = false;

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get pendingEmail => _pendingEmail;
  bool get needsOtp => _needsOtp;

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
          avatarUrl: prefs.getString('driver_avatar_url'),
          dateOfBirth: prefs.getString('driver_dob'),
          residentialAddress: prefs.getString('driver_residential_address'),
          stateLga: prefs.getString('driver_state_lga'),
          emergencyContactName: prefs.getString('driver_emergency_name'),
          emergencyContactPhone: prefs.getString('driver_emergency_phone'),
          emergencyContactRelationship: prefs.getString('driver_emergency_relationship'),
          ninNumber: prefs.getString('driver_nin'),
          driverLicenseImage: prefs.getString('driver_license_image'),
          licenseNumber: prefs.getString('driver_license') ?? 'LG-2023-0048291',
          vehiclePlate: prefs.getString('driver_plate') ?? 'LND-394-FY',
          isVerified: true,
          isOnline: true,
          isProfileCompleted: prefs.getBool('driver_profile_completed') ?? false,
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

  Future<void> _persistDriver(DriverModel driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_logged_in', true);
    await prefs.setString('driver_id', driver.id);
    await prefs.setString('driver_email', driver.email);
    await prefs.setString('driver_first_name', driver.firstName);
    await prefs.setString('driver_last_name', driver.lastName);
    await prefs.setString('driver_phone', driver.phone);
    await prefs.setBool('driver_profile_completed', driver.isProfileCompleted);
    if (driver.avatarUrl != null) await prefs.setString('driver_avatar_url', driver.avatarUrl!);
    if (driver.dateOfBirth != null) await prefs.setString('driver_dob', driver.dateOfBirth!);
    if (driver.residentialAddress != null) {
      await prefs.setString('driver_residential_address', driver.residentialAddress!);
    }
    if (driver.stateLga != null) await prefs.setString('driver_state_lga', driver.stateLga!);
    if (driver.emergencyContactName != null) {
      await prefs.setString('driver_emergency_name', driver.emergencyContactName!);
    }
    if (driver.emergencyContactPhone != null) {
      await prefs.setString('driver_emergency_phone', driver.emergencyContactPhone!);
    }
    if (driver.emergencyContactRelationship != null) {
      await prefs.setString('driver_emergency_relationship', driver.emergencyContactRelationship!);
    }
    if (driver.ninNumber != null) await prefs.setString('driver_nin', driver.ninNumber!);
    if (driver.driverLicenseImage != null) {
      await prefs.setString('driver_license_image', driver.driverLicenseImage!);
    }
    if (driver.licenseNumber != null) {
      await prefs.setString('driver_license', driver.licenseNumber!);
    }
    if (driver.vehiclePlate != null) {
      await prefs.setString('driver_plate', driver.vehiclePlate!);
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

      if (res.data != null && (res.data as Map<String, dynamic>)['requiresOtp'] == true) {
        _pendingEmail = email.trim();
        _needsOtp = true;
        _errorMessage = (res.data as Map<String, dynamic>)['error'] ??
            'Verification required. Code sent to your email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (res.isSuccess && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        await ApiClient.instance.setToken(token);

        if (data['driver'] != null) {
          _driver = DriverModel.fromJson(data['driver'] as Map<String, dynamic>);
          await _persistDriver(_driver!);
        }

        _pendingEmail = null;
        _needsOtp = false;
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

        if (data['requiresOtp'] == true) {
          _pendingEmail = email.trim();
          _needsOtp = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }

        final token = data['token'] as String?;
        await ApiClient.instance.setToken(token);

        if (data['driver'] != null) {
          _driver = DriverModel.fromJson(data['driver'] as Map<String, dynamic>);
          await _persistDriver(_driver!);
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

  Future<bool> verifyOtp(String otp, {String? email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final targetEmail = (email ?? _pendingEmail ?? _driver?.email ?? '').trim();
    if (targetEmail.isEmpty) {
      _errorMessage = 'No email associated with this verification attempt';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await ApiClient.instance.post('/api/driver/verify-otp', {
        'email': targetEmail,
        'otp': otp.trim(),
      });

      if (res.isSuccess && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        await ApiClient.instance.setToken(token);

        if (data['driver'] != null) {
          _driver = DriverModel.fromJson(data['driver'] as Map<String, dynamic>);
          await _persistDriver(_driver!);
        }

        _pendingEmail = null;
        _needsOtp = false;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.errorMessage ?? 'Invalid verification code';
      }
    } catch (e) {
      debugPrint('Driver OTP verify error: $e');
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> resendOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post('/api/driver/resend-otp', {
        'email': email.trim(),
      });

      _isLoading = false;
      notifyListeners();
      return res.isSuccess;
    } catch (e) {
      debugPrint('Driver resend OTP error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Complete KYC Profile
  Future<bool> completeProfile({
    required String fullName,
    required String dateOfBirth,
    required String phone,
    required String residentialAddress,
    required String stateLga,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String emergencyContactRelationship,
    required String ninNumber,
    String? email,
    String? avatarUrl,
    String? driverLicenseImage,
    String? licenseNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post('/api/driver/complete-profile', {
        'driverId': _driver?.id,
        'email': (email ?? _driver?.email ?? _pendingEmail ?? '').trim(),
        'fullName': fullName.trim(),
        'dateOfBirth': dateOfBirth.trim(),
        'phone': phone.trim(),
        'residentialAddress': residentialAddress.trim(),
        'stateLga': stateLga.trim(),
        'emergencyContactName': emergencyContactName.trim(),
        'emergencyContactPhone': emergencyContactPhone.trim(),
        'emergencyContactRelationship': emergencyContactRelationship.trim(),
        'ninNumber': ninNumber.trim(),
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
        if (driverLicenseImage != null && driverLicenseImage.isNotEmpty)
          'driverLicenseImage': driverLicenseImage,
        if (licenseNumber != null && licenseNumber.isNotEmpty)
          'licenseNumber': licenseNumber.trim(),
      });

      if (res.isSuccess && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (data['driver'] != null) {
          _driver = DriverModel.fromJson(data['driver'] as Map<String, dynamic>);
          await _persistDriver(_driver!);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.errorMessage ?? 'Failed to complete profile';
      }
    } catch (e) {
      debugPrint('Driver complete profile error: $e');
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    if (_driver == null) return;
    try {
      final res = await ApiClient.instance.get('/api/driver/profile?driverId=${_driver!.id}');
      if (res.isSuccess && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (data['driver'] != null) {
          _driver = DriverModel.fromJson(data['driver'] as Map<String, dynamic>);
          await _persistDriver(_driver!);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
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
