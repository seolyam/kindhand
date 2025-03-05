import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UserProfileService {
  static const String baseUrl = 'https://kindhand.helioho.st/kindhand-api/api';

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (kDebugMode) {
        print('Retrieved User ID from SharedPreferences: $userId');
      }

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile.php?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (kDebugMode) {
        print('User Profile API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return decodedResponse['data'];
        } else {
          throw Exception(
              decodedResponse['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserProfile: $e');
      }
      rethrow;
    }
  }
}
