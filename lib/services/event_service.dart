import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class EventService {
  static const String baseUrl = 'https://kindhand.helioho.st/kindhand-api/api';
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 8);
  static const int maxRetries = 3;

  // Cache management
  static const String cachePrefix = 'events_cache_';
  static const String cacheTimePrefix = 'events_cache_time_';
  static const Duration cacheValidDuration = Duration(minutes: 5);

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

      final response = await _makeRequest(
        () => http
            .post(
              Uri.parse('$baseUrl/events/create.php'),
              headers: {"Content-Type": "application/json"},
              body: json.encode(eventData),
            )
            .timeout(defaultTimeout),
        retries: 2,
      );

      if (kDebugMode) {
        debugPrint('Create Event API Response: ${response.body}');
        debugPrint('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        // Clear cache after creating new event
        await _clearEventsCache();
        return json.decode(response.body);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in createEvent: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getEvents({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first if enabled and not forcing refresh
      if (useCache && !forceRefresh) {
        final cachedEvents = await _getCachedEvents();
        if (cachedEvents != null) {
          if (kDebugMode) {
            debugPrint('Using cached events (${cachedEvents.length} items)');
          }
          return cachedEvents;
        }
      }

      final response = await _makeRequest(
        () => http.get(
          Uri.parse('$baseUrl/events/read.php'),
          headers: {"Content-Type": "application/json"},
        ).timeout(defaultTimeout),
        retries: maxRetries,
      );

      if (kDebugMode) {
        debugPrint(
            'Get Events API Response Length: ${response.body.length} characters');
        debugPrint('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          final events =
              List<Map<String, dynamic>>.from(decodedResponse['data']);

          // Cache the events if caching is enabled
          if (useCache) {
            await _cacheEvents(events);
          }

          return events;
        } else {
          throw Exception(
              decodedResponse['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in getEvents: $e');
      }

      // Try to return cached data as fallback
      if (useCache) {
        final cachedEvents = await _getCachedEvents(ignoreExpiry: true);
        if (cachedEvents != null) {
          if (kDebugMode) {
            debugPrint(
                'Using expired cache as fallback (${cachedEvents.length} items)');
          }
          return cachedEvents;
        }
      }

      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateEvent(
      int eventId, Map<String, dynamic> eventData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Add the event ID and user ID to the request body
      eventData['id'] = eventId;
      eventData['updated_by'] = userId;

      final response = await _makeRequest(
        () => http
            .post(
              Uri.parse('$baseUrl/events/update.php'),
              headers: {"Content-Type": "application/json"},
              body: json.encode(eventData),
            )
            .timeout(defaultTimeout),
        retries: 2,
      );

      if (kDebugMode) {
        debugPrint('Update Event API Response: ${response.body}');
        debugPrint('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        // Clear cache after updating event
        await _clearEventsCache();
        return json.decode(response.body);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in updateEvent: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteEvent(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await _makeRequest(
        () => http
            .post(
              Uri.parse('$baseUrl/events/delete.php'),
              headers: {"Content-Type": "application/json"},
              body: json.encode({'id': eventId, 'deleted_by': userId}),
            )
            .timeout(defaultTimeout),
        retries: 2,
      );

      if (kDebugMode) {
        debugPrint('Delete Event API Response: ${response.body}');
        debugPrint('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        // Clear cache after deleting event
        await _clearEventsCache();
        return json.decode(response.body);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in deleteEvent: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<Map<String, dynamic>> getEventDetails(int eventId) async {
    try {
      final response = await _makeRequest(
        () => http.get(
          Uri.parse('$baseUrl/events/read_one.php?id=$eventId'),
          headers: {"Content-Type": "application/json"},
        ).timeout(shortTimeout),
        retries: 2,
      );

      if (kDebugMode) {
        debugPrint(
            'Get Event Details API Response Length: ${response.body.length}');
        debugPrint('Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'data': decodedResponse['data'],
            'message': decodedResponse['message'] ??
                'Event details retrieved successfully'
          };
        } else {
          return {
            'success': false,
            'message':
                decodedResponse['message'] ?? 'Failed to retrieve event details'
          };
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in getEventDetails: $e');
      }
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Helper method to make requests with retry logic
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFunction, {
    int retries = 3,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < retries) {
      try {
        attempt++;
        if (kDebugMode && attempt > 1) {
          debugPrint('Retry attempt $attempt/$retries');
        }

        final response = await requestFunction();
        return response;
      } on TimeoutException catch (e) {
        lastException = e;
        if (kDebugMode) {
          debugPrint('Request timeout on attempt $attempt: $e');
        }

        if (attempt < retries) {
          // Exponential backoff: wait 1s, then 2s, then 4s
          final delay = Duration(seconds: 1 << (attempt - 1));
          if (kDebugMode) {
            debugPrint('Waiting ${delay.inSeconds}s before retry...');
          }
          await Future.delayed(delay);
        }
      } on Exception catch (e) {
        lastException = e;
        if (kDebugMode) {
          debugPrint('Request failed on attempt $attempt: $e');
        }

        // For non-timeout exceptions, only retry if it's a connection issue
        if (e.toString().contains('Connection') ||
            e.toString().contains('Network') ||
            e.toString().contains('SocketException')) {
          if (attempt < retries) {
            final delay = Duration(seconds: 1 << (attempt - 1));
            await Future.delayed(delay);
          }
        } else {
          // For other exceptions, don't retry
          rethrow;
        }
      }
    }

    // If we've exhausted all retries, throw the last exception
    throw lastException ?? Exception('Request failed after $retries attempts');
  }

  // Cache management methods
  static Future<void> _cacheEvents(List<Map<String, dynamic>> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = json.encode(events);
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString('${cachePrefix}events', eventsJson);
      await prefs.setInt('${cacheTimePrefix}events', currentTime);

      if (kDebugMode) {
        debugPrint('Cached ${events.length} events');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error caching events: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>?> _getCachedEvents({
    bool ignoreExpiry = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEventsJson = prefs.getString('${cachePrefix}events');
      final cacheTime = prefs.getInt('${cacheTimePrefix}events');

      if (cachedEventsJson == null || cacheTime == null) {
        return null;
      }

      if (!ignoreExpiry) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final cacheAge = Duration(milliseconds: currentTime - cacheTime);

        if (cacheAge > cacheValidDuration) {
          if (kDebugMode) {
            debugPrint('Cache expired (age: ${cacheAge.inMinutes} minutes)');
          }
          return null;
        }
      }

      final eventsList = json.decode(cachedEventsJson) as List;
      return List<Map<String, dynamic>>.from(eventsList);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading cached events: $e');
      }
      return null;
    }
  }

  static Future<void> _clearEventsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${cachePrefix}events');
      await prefs.remove('${cacheTimePrefix}events');

      if (kDebugMode) {
        debugPrint('Events cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing events cache: $e');
      }
    }
  }

  // Public method to clear cache
  static Future<void> clearCache() async {
    await _clearEventsCache();
  }

  // Method to check network connectivity
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .head(
            Uri.parse('$baseUrl/health.php'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Connectivity check failed: $e');
      }
      return false;
    }
  }
}
