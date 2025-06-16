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

  /// Get another user's profile by ID with fallback to search API
  static Future<Map<String, dynamic>> getOtherUserProfile(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/get_profile.php?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('Get Other User Profile API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      // If the API endpoint doesn't exist (404), use the search API to get user data
      if (response.statusCode == 404) {
        if (kDebugMode) {
          print('Profile API returned 404, trying search API fallback...');
        }
        return await _getUserFromSearchAPI(userId);
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return decodedResponse['data'];
        } else {
          throw Exception(
              decodedResponse['message'] ?? 'Failed to retrieve user profile');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getOtherUserProfile: $e');
      }
      // Try to get user from search API as fallback
      try {
        if (kDebugMode) {
          print('Attempting search API fallback for user $userId...');
        }
        return await _getUserFromSearchAPI(userId);
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Search API fallback also failed: $fallbackError');
        }
        throw Exception('Failed to load user profile: $e');
      }
    }
  }

  /// Fallback method to get user data from search API
  static Future<Map<String, dynamic>> _getUserFromSearchAPI(int userId) async {
    try {
      // Try multiple search strategies to find the user
      final searchQueries = ['gmail', 'ph', 'com', 'dev', 'vol'];

      for (String query in searchQueries) {
        final uri =
            Uri.parse('$baseUrl/user/search_users.php?query=$query&limit=100');
        final response = await http.get(
          uri,
          headers: {"Content-Type": "application/json"},
        ).timeout(const Duration(seconds: 5));

        if (kDebugMode) {
          print(
              'Search API Fallback ($query) Response Status: ${response.statusCode}');
          print('Search API Fallback ($query) Response: ${response.body}');
        }

        if (response.statusCode == 200) {
          final decodedResponse = json.decode(response.body);

          List<Map<String, dynamic>> users = [];

          if (decodedResponse['success'] == true) {
            if (decodedResponse['data'] is List) {
              users = List<Map<String, dynamic>>.from(decodedResponse['data']);
            }

            // Find the user with matching ID
            for (var user in users) {
              if (user['user_id'].toString() == userId.toString()) {
                if (kDebugMode) {
                  print(
                      'Found user in search results with "$query": ${user['first_name']} ${user['last_name']}');
                }
                return _convertSearchResultToProfile(user);
              }
            }
          }
        }
      }

      throw Exception('User not found in search results');
    } catch (e) {
      if (kDebugMode) {
        print('Error in _getUserFromSearchAPI: $e');
      }
      rethrow;
    }
  }

  /// Convert search API result format to profile format
  static Map<String, dynamic> _convertSearchResultToProfile(
      Map<String, dynamic> searchResult) {
    // Handle skills - if they're empty in the search result, we need to try to fetch them from the profile API
    List<String> skillsList = _parseSkillsFromData(searchResult['skills']);

    if (kDebugMode) {
      print(
          'Converting search result to profile for user: ${searchResult['first_name']} ${searchResult['last_name']}');
      print('Skills from search API: ${searchResult['skills']}');
      print('Parsed skills: $skillsList');
    }

    // Create the profile data
    Map<String, dynamic> profileData = {
      'user_id': searchResult['user_id'],
      'firstName': searchResult['first_name'] ?? '',
      'lastName': searchResult['last_name'] ?? '',
      'first_name': searchResult['first_name'] ?? '',
      'last_name': searchResult['last_name'] ?? '',
      'email': searchResult['email'] ?? '',
      'bio': searchResult['bio'] ?? '',
      'location': searchResult['location'] ?? '',
      'country': searchResult['country'] ?? '',
      'volunteerType': searchResult['volunteer_type'] ?? '',
      'volunteer_type': searchResult['volunteer_type'] ?? '',
      'user_type': searchResult['user_type'] ?? '',
      'skills': skillsList,
      'education': [],
      'badges': [],
    };

    // If skills are empty, try to fetch them directly from the profile API
    if (skillsList.isEmpty) {
      _fetchSkillsFromProfileAPI(int.parse(searchResult['user_id'].toString()))
          .then((fetchedSkills) {
        if (fetchedSkills.isNotEmpty && kDebugMode) {
          print('Fetched skills from profile API: $fetchedSkills');
        }
      });
    }

    return profileData;
  }

// Add this new method to fetch skills directly from the profile API
  /// Fetch skills directly from the profile API as a fallback
  static Future<List<String>> _fetchSkillsFromProfileAPI(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/get_profile.php?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          final profileData = decodedResponse['data'];
          return _parseSkillsFromData(profileData['skills']);
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching skills from profile API: $e');
      }
      return [];
    }
  }

  /// Parse skills using the same robust logic as edit profile screen
  static List<String> _parseSkillsFromData(dynamic skillsData) {
    try {
      if (skillsData == null) {
        return [];
      }

      if (kDebugMode) {
        print("Raw skills data: $skillsData");
        print("Skills data type: ${skillsData.runtimeType}");
      }

      if (skillsData is String) {
        // Handle empty arrays
        if (skillsData == "[]" ||
            skillsData == "\"[]\"" ||
            skillsData.isEmpty) {
          return [];
        }

        // Remove outer quotes if present (handles double encoding)
        String processedData = skillsData;
        if (processedData.startsWith('"') && processedData.endsWith('"')) {
          processedData = processedData.substring(1, processedData.length - 1);
          // Unescape inner quotes
          processedData = processedData.replaceAll('\\"', '"');
        }

        try {
          dynamic decoded = jsonDecode(processedData);
          if (decoded is List) {
            return List<String>.from(decoded.map((item) => item.toString()));
          } else {
            return [];
          }
        } catch (e) {
          if (kDebugMode) print("Skills JSON parse error: $e");
          // If parsing fails, use as a single skill if it's not empty
          if (processedData.isNotEmpty && processedData != "[]") {
            return [processedData];
          } else {
            return [];
          }
        }
      } else if (skillsData is List) {
        return List<String>.from(skillsData.map((item) => item.toString()));
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing skills: $e');
      return [];
    }
  }

  /// Get user statistics (events participated, volunteer hours, etc.)
  static Future<Map<String, dynamic>> getUserStatistics(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/user_statistics.php?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('User Statistics API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return decodedResponse['data'];
        } else {
          return {};
        }
      } else if (response.statusCode == 404) {
        // API endpoint doesn't exist yet
        return {};
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserStatistics: $e');
      }
      return {};
    }
  }

  /// Check if current user can view another user's profile
  static Future<bool> canViewProfile(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      if (currentUserId == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/user/can_view_profile.php?user_id=$userId&current_user_id=$currentUserId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('Can View Profile API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse['success'] == true &&
            decodedResponse['can_view'] == true;
      } else if (response.statusCode == 404) {
        // API endpoint doesn't exist yet, allow viewing by default
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in canViewProfile: $e');
      }
      // Default to allowing profile viewing if API fails
      return true;
    }
  }

  /// Get user's public profile (limited information for privacy)
  static Future<Map<String, dynamic>> getPublicProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/public_profile.php?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('Public Profile API Response: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return decodedResponse['data'];
        } else {
          throw Exception(decodedResponse['message'] ??
              'Failed to retrieve public profile');
        }
      } else if (response.statusCode == 404) {
        // Fallback to regular profile method
        return await getOtherUserProfile(userId);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getPublicProfile: $e');
      }
      // Fallback to regular profile method
      try {
        return await getOtherUserProfile(userId);
      } catch (fallbackError) {
        throw Exception('Failed to load public profile: $e');
      }
    }
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/user/update_profile.php'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(apiData),
          )
          .timeout(const Duration(seconds: 10));

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
