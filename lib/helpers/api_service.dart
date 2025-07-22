import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.43.129:4000/api';
    } else {
      return 'http://localhost:4000/api';
    }
  } // Replace with your backend URL

  static const Duration timeout = Duration(seconds: 10); // Add timeout

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    return http
        .get(
          Uri.parse('$baseUrl/$endpoint'),
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        )
        .timeout(timeout);
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    return http
        .post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode(data),
        )
        .timeout(timeout);
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    return http
        .put(
          Uri.parse('$baseUrl/$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode(data),
        )
        .timeout(timeout);
  }

  static Future<http.Response> delete(String endpoint) async {
    final token = await getToken();
    return http
        .delete(
          Uri.parse('$baseUrl/$endpoint'),
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        )
        .timeout(timeout);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // If connectivity check fails, assume offline
      return false;
    }
  }

  static Future<bool> batchSync(Map<String, dynamic> allData) async {
    try {
      final response = await post('sync', allData);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend connection test failed: $e');
      return false;
    }
  }
}
