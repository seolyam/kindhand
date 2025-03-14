import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://kindhand.helioho.st/kindhand-api/api';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      body: {'email': email, 'password': password},
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> register(
    String firstName,
    String lastName,
    String email,
    String password,
    String userType,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'user_type': userType,
      },
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/get_profile.php?user_id=$userId'));
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile(
      String userId, String username, String website) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_profile.php'),
      body: {'user_id': userId, 'username': username, 'website': website},
    );
    return json.decode(response.body);
  }
}
