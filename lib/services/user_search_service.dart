import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class UserSearchService {
  static const String baseUrl = 'https://kindhand.helioho.st/kindhand-api/api';

  /// Search for users with optional filters
  static Future<Map<String, dynamic>> searchUsers({
    String? query,
    String? location,
    String? country,
    String? volunteerType,
    String? userType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};

      // Use a default query if none provided to get all users
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      } else {
        queryParams['query'] =
            'a'; // Get all users with 'a' in their name/email
      }

      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (country != null && country.isNotEmpty) {
        queryParams['country'] = country;
      }
      if (volunteerType != null && volunteerType.isNotEmpty) {
        queryParams['volunteer_type'] = volunteerType;
      }
      if (userType != null && userType.isNotEmpty) {
        queryParams['user_type'] = userType;
      }
      queryParams['limit'] = limit.toString();
      queryParams['offset'] = offset.toString();

      if (kDebugMode) {
        print('Search Users API Request URL: $baseUrl/user/search_users.php');
        print('Search Users API Request Params: $queryParams');
      }

      final uri = Uri.parse('$baseUrl/user/search_users.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (kDebugMode) {
        print('Search Users API Response Status: ${response.statusCode}');
        print('Search Users API Response Body: ${response.body}');
      }

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned empty response',
          'data': []
        };
      }

      try {
        final decodedResponse = json.decode(response.body);

        // Handle both nested and direct response structures
        if (decodedResponse['success'] == true) {
          if (decodedResponse['data'] is Map &&
              decodedResponse['data']['data'] is List) {
            // Nested structure
            return {
              'success': true,
              'message': decodedResponse['data']['message'] ?? 'Success',
              'data': decodedResponse['data']['data'],
              'count': decodedResponse['data']['count'] ?? 0
            };
          } else if (decodedResponse['data'] is List) {
            // Direct structure
            return decodedResponse;
          }
        }

        return decodedResponse;
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing JSON response: $e');
        }
        return {
          'success': false,
          'message': 'Failed to parse server response',
          'data': []
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in searchUsers: $e');
      }
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  /// Get all users (for initial load)
  static Future<List<Map<String, dynamic>>> getAllUsers(
      {int limit = 50}) async {
    try {
      final response = await searchUsers(query: 'a', limit: limit);
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      return [];
    }
  }
}
