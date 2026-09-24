import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiResponse {
  final bool isSuccess;
  final int statusCode;
  final dynamic data;
  final String? errorMessage;

  const ApiResponse({
    required this.isSuccess,
    required this.statusCode,
    this.data,
    this.errorMessage,
  });
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  String get baseUrl => AppConstants.apiBaseUrl;

  String? get token => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.keyAuthToken);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(AppConstants.keyAuthToken, token);
    } else {
      await prefs.remove(AppConstants.keyAuthToken);
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<ApiResponse> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      final decoded = _tryDecodeJson(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResponse(
          isSuccess: true,
          statusCode: res.statusCode,
          data: decoded,
        );
      } else {
        final errorMsg = decoded is Map
            ? (decoded['error'] ?? decoded['message'] ?? 'Request failed')
            : 'Request failed (${res.statusCode})';
        return ApiResponse(
          isSuccess: false,
          statusCode: res.statusCode,
          errorMessage: errorMsg.toString(),
          data: decoded,
        );
      }
    } catch (e) {
      debugPrint('API POST error ($endpoint): $e');
      return ApiResponse(
        isSuccess: false,
        statusCode: 0,
        errorMessage: 'Network error: Please check your internet connection.',
      );
    }
  }

  Future<ApiResponse> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      final decoded = _tryDecodeJson(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResponse(
          isSuccess: true,
          statusCode: res.statusCode,
          data: decoded,
        );
      } else {
        final errorMsg = decoded is Map
            ? (decoded['error'] ?? decoded['message'] ?? 'Request failed')
            : 'Request failed (${res.statusCode})';
        return ApiResponse(
          isSuccess: false,
          statusCode: res.statusCode,
          errorMessage: errorMsg.toString(),
          data: decoded,
        );
      }
    } catch (e) {
      debugPrint('API GET error ($endpoint): $e');
      return ApiResponse(
        isSuccess: false,
        statusCode: 0,
        errorMessage: 'Network error: Please check your internet connection.',
      );
    }
  }

  Future<ApiResponse> uploadFile({
    required List<int> bytes,
    required String fileName,
    String folder = 'uploads',
  }) async {
    final url = Uri.parse('$baseUrl/api/upload');
    try {
      final request = http.MultipartRequest('POST', url);
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      final decoded = _tryDecodeJson(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResponse(
          isSuccess: true,
          statusCode: res.statusCode,
          data: decoded,
        );
      } else {
        final errorMsg = decoded is Map
            ? (decoded['error'] ?? decoded['message'] ?? 'Upload failed')
            : 'Upload failed (${res.statusCode})';
        return ApiResponse(
          isSuccess: false,
          statusCode: res.statusCode,
          errorMessage: errorMsg.toString(),
          data: decoded,
        );
      }
    } catch (e) {
      debugPrint('API upload error: $e');
      return const ApiResponse(
        isSuccess: false,
        statusCode: 0,
        errorMessage: 'Network error during file upload.',
      );
    }
  }

  dynamic _tryDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return source;
    }
  }
}
