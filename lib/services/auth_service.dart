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
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Ensure user_id is stored as a string
          final userId = data['data']['user_id'].toString();
          final userEmail = data['data']['email'] ?? email;

          // Get user_type from response or default to 'volunteer'
          final userType = data['data']['user_type'] ?? 'volunteer';

          if (kDebugMode) {
            print('USER TYPE FROM API: $userType');
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', userId);
          await prefs.setString('user_email', userEmail);
          await prefs.setString('user_type', userType);

          if (kDebugMode) {
            print('User ID stored in SharedPreferences: $userId');
            print('User Email stored in SharedPreferences: $userEmail');
            print('User Type stored in SharedPreferences: $userType');
          }
        }
        return data;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login Error: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
      String firstName, String lastName, String email, String password,
      {String userType = 'volunteer', String country = 'Philippines'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
          "userType": userType,
          "country": country
        }),
      );

      if (kDebugMode) {
        print('Register Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] &&
            data['data'] != null &&
            data['data']['user_id'] != null) {
          // Store user info in SharedPreferences if registration is successful
          final userId = data['data']['user_id'].toString();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', userId);
          await prefs.setString('user_email', email);
          await prefs.setString('user_type', userType);

          if (kDebugMode) {
            print(
                'User ID stored in SharedPreferences after registration: $userId');
            print(
                'User Type stored in SharedPreferences after registration: $userType');
          }
        }
        return data;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Register Error: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (kDebugMode && userId != null) {
      print('Retrieved User ID from SharedPreferences: $userId');
    }

    return userId;
  }

  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');

    if (kDebugMode && userEmail != null) {
      print('Retrieved User Email from SharedPreferences: $userEmail');
    }

    return userEmail;
  }

  static Future<String> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');

    if (kDebugMode) {
      print('Retrieved User Type from SharedPreferences: $userType');
    }

    return userType ?? 'volunteer';
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }

  static Future<bool> isOrganization() async {
    final userType = await getUserType();
    return userType.toLowerCase() == 'organization';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
