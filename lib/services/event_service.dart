import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class EventService {
  static const String baseUrl = 'https://kindhand.helioho.st/kindhand-api/api';

  static Future<Map<String, dynamic>> createEvent(
      Map<String, dynamic> eventData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Add user_id to the event data
      eventData['created_by'] = userId;

      final response = await http.post(
        Uri.parse('$baseUrl/events/create.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(eventData),
      );

      if (kDebugMode) {
        print('Create Event API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in createEvent: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/read.php'),
        headers: {"Content-Type": "application/json"},
      );

      if (kDebugMode) {
        print('Get Events API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return List<Map<String, dynamic>>.from(decodedResponse['data']);
        } else {
          throw Exception(
              decodedResponse['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getEvents: $e');
      }
      rethrow;
    }
  }
}
