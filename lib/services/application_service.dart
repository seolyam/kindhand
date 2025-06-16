import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApplicationService {
  static const String baseUrl = 'https://kindhand.helioho.st/kindhand-api/api';

  // Apply to an event (volunteer or interested)
  static Future<Map<String, dynamic>> applyToEvent({
    required int eventId,
    required String applicationType,
    String? message,
    bool withdraw = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/events/apply.php'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "event_id": eventId,
              "user_id": userId,
              "application_type": applicationType,
              "message": message,
              "withdraw": withdraw,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('Apply to Event Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in applyToEvent: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Check application status
  static Future<Map<String, dynamic>> checkApplicationStatus(
      int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/events/check_application.php?event_id=$eventId&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('Check Application Status Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(
              data['message'] ?? 'Failed to check application status');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkApplicationStatus: $e');
      }
      return {
        'has_volunteer_application': false,
        'has_interested_application': false,
      };
    }
  }

  // Get applications for an event
  static Future<List<Map<String, dynamic>>> getEventApplications({
    required int eventId,
    String? type,
    String? status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      String url =
          '$baseUrl/events/applications.php?event_id=$eventId&user_id=$userId';
      if (type != null) {
        url += '&type=$type';
      }
      if (status != null) {
        url += '&status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('Get Event Applications Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get applications');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getEventApplications: $e');
      }
      return [];
    }
  }

  /// Get volunteer history for a specific user with improved error handling
  static Future<List<Map<String, dynamic>>> getUserVolunteerHistory(
      int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/events/user_history.php?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('Get User History Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      // If the API endpoint doesn't exist (404), return empty list
      if (response.statusCode == 404) {
        if (kDebugMode) {
          print(
              'User history API endpoint not found (404), returning empty list');
        }
        return [];
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          if (kDebugMode) {
            print(
                'User history API returned success=false: ${data['message']}');
          }
          return [];
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserVolunteerHistory: $e');
      }
      return [];
    }
  }

  /// Check application status for a specific user with improved error handling
  static Future<Map<String, dynamic>> checkApplicationStatusForUser({
    required int eventId,
    required int userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/events/check_application.php?event_id=$eventId&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('Check Application Status For User Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      // If the API endpoint doesn't exist (404), return empty status
      if (response.statusCode == 404) {
        if (kDebugMode) {
          print(
              'Application status API endpoint not found (404), returning default status');
        }
        return {
          'has_volunteer_application': false,
          'has_interested_application': false,
          'volunteer_status': 'unknown',
          'interested_status': 'unknown',
        };
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          if (kDebugMode) {
            print(
                'Application status API returned success=false: ${data['message']}');
          }
          return {
            'has_volunteer_application': false,
            'has_interested_application': false,
            'volunteer_status': 'unknown',
            'interested_status': 'unknown',
          };
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkApplicationStatusForUser: $e');
      }
      return {
        'has_volunteer_application': false,
        'has_interested_application': false,
        'volunteer_status': 'unknown',
        'interested_status': 'unknown',
      };
    }
  }

  // Update application status
  static Future<Map<String, dynamic>> updateApplicationStatus({
    required int applicationId,
    required String status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/events/update_application.php'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "application_id": applicationId,
              "status": status,
              "user_id": userId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('Update Application Status Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateApplicationStatus: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
