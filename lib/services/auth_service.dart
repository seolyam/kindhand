import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = 'https://kindhand.helioho.st/kindhand-api/api';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );

      if (kDebugMode) {
        print('Login Response: ${response.body}');
      }

      final data = json.decode(response.body);
      if (data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['data']['user_id'].toString());
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Login Error: $e');
      }
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username, // Include this field
          "email": email,
          "password": password
        }),
      );

      if (kDebugMode) {
        print('Register Response: ${response.body}');
      }

      return json.decode(response.body);
    } catch (e) {
      if (kDebugMode) {
        print('Register Error: $e');
      }
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }
}
