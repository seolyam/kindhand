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
      final userEmail = prefs.getString('user_email') ??
          ''; // Get email from SharedPreferences

      if (kDebugMode) {
        print('Retrieved User ID from SharedPreferences: $userId');
        print('Retrieved User Email from SharedPreferences: $userEmail');
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
          // Instead of throwing an exception, return a default empty profile
          if (kDebugMode) {
            print('Profile not found, returning default empty profile');
          }
          return _getDefaultProfile(userId, userEmail);
        }
      } else if (response.statusCode == 500) {
        // Handle 500 error specifically for "User profile not found"
        if (kDebugMode) {
          print('Server error, returning default empty profile');
        }
        return _getDefaultProfile(userId, userEmail);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserProfile: $e');
      }
      // For any other errors, still try to return a default profile
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email') ?? '';
      if (userId != null) {
        return _getDefaultProfile(userId, userEmail);
      }
      rethrow;
    }
  }

  // Helper method to create a default empty profile with email pre-filled
  static Map<String, dynamic> _getDefaultProfile(String userId, String email) {
    return {
      'user_id': userId,
      'firstName': '',
      'lastName': '',
      'email': email, // Pre-fill with email from registration
      'bio': '',
      'location': '',
      'country': 'Philippines',
      'volunteerType': 'Online',
      'skills': <String>[],
      'education': <Map<String, String>>[],
      'status': '',
      'isNewProfile': true, // Flag to indicate this is a new profile
    };
  }

  // Add method to save profile to database
  static Future<bool> saveUserProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Ensure user_id is included in the profile data
      profileData['user_id'] = userId;

      // Convert skills and education to JSON strings for API
      final apiData = Map<String, dynamic>.from(profileData);
      apiData['skills'] = jsonEncode(profileData['skills']);
      apiData['education'] = jsonEncode(profileData['education']);

      final response = await http.post(
        Uri.parse('$baseUrl/user/update_profile.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(apiData),
      );

      if (kDebugMode) {
        print('Save Profile API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse['success'] == true;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in saveUserProfile: $e');
      }
      return false;
    }
  }
}
