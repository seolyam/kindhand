import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'view_user_profile_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  SearchUserScreenState createState() => SearchUserScreenState();
}

class SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showFilters = false;
  bool _hasSearched = false;

  // Filter options
  String? _selectedCountry;
  String? _selectedVolunteerType;

  final List<String> _countries = [
    'Philippines',
    'United States',
    'Canada',
    'Australia',
    'United Kingdom'
  ];
  final List<String> _volunteerTypes = ['Online', 'On-site', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    _loadAllUsers(); // Load all users initially
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to get all users (with empty query)
      final uri = Uri.parse(
          'https://kindhand.helioho.st/kindhand-api/api/user/search_users.php?query=a&limit=50');

      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5)); // Add timeout

      if (kDebugMode) {
        print('Load All Users API Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        List<Map<String, dynamic>> users = [];

        // Handle nested response structure
        if (decodedResponse['success'] == true) {
          if (decodedResponse['data'] is Map &&
              decodedResponse['data']['data'] is List) {
            // Nested structure
            users = List<Map<String, dynamic>>.from(
                decodedResponse['data']['data']);
          } else if (decodedResponse['data'] is List) {
            // Direct structure
            users = List<Map<String, dynamic>>.from(decodedResponse['data']);
          }
        }

        setState(() {
          _allUsers = users;
          _searchResults = users;
          _isLoading = false;
          _hasSearched = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load users (${response.statusCode})';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading users: $e');
      }
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Connection error. Please check your internet and try again.';
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    final location = _locationController.text.toLowerCase().trim();

    if (query.isEmpty &&
        location.isEmpty &&
        _selectedCountry == null &&
        _selectedVolunteerType == null) {
      setState(() {
        _searchResults = _allUsers;
      });
      return;
    }

    List<Map<String, dynamic>> filtered = _allUsers.where((user) {
      // Pre-compute user data for efficiency
      final firstName = (user['first_name'] ?? '').toString().toLowerCase();
      final lastName = (user['last_name'] ?? '').toString().toLowerCase();
      final fullName = '$firstName $lastName';
      final email = (user['email'] ?? '').toString().toLowerCase();
      final bio = (user['bio'] ?? '').toString().toLowerCase();
      final userLocation = (user['location'] ?? '').toString().toLowerCase();
      final userCountry = (user['country'] ?? '').toString();
      final userVolunteerType = (user['volunteer_type'] ?? '').toString();

      // Text search - check if query matches any field
      bool matchesQuery = query.isEmpty ||
          firstName.contains(query) ||
          lastName.contains(query) ||
          fullName.contains(query) ||
          email.contains(query) ||
          bio.contains(query) ||
          userLocation.contains(query);

      // Location filter
      bool matchesLocation =
          location.isEmpty || userLocation.contains(location);

      // Country filter
      bool matchesCountry =
          _selectedCountry == null || userCountry == _selectedCountry;

      // Volunteer type filter
      bool matchesVolunteerType = _selectedVolunteerType == null ||
          userVolunteerType == _selectedVolunteerType;

      return matchesQuery &&
          matchesLocation &&
          matchesCountry &&
          matchesVolunteerType;
    }).toList();

    setState(() {
      _searchResults = filtered;
    });
  }

  /// Parse skills using the same robust logic as profile screen
  List<String> _parseSkills(dynamic skillsData) {
    try {
      if (skillsData == null) {
        return [];
      }

      if (kDebugMode) {
        print("Raw skills data in search: $skillsData");
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
            final result =
                List<String>.from(decoded.map((item) => item.toString()));
            if (kDebugMode) print("Parsed skills successfully: $result");
            return result;
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
        final result =
            List<String>.from(skillsData.map((item) => item.toString()));
        if (kDebugMode) print("Skills already a list: $result");
        return result;
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing skills: $e');
      return [];
    }
  }

  /// Fetch skills for a user directly from the profile API
  Future<List<String>> _fetchUserSkills(int userId) async {
    try {
      if (kDebugMode) {
        print('Fetching skills directly for user $userId');
      }

      final response = await http.get(
        Uri.parse(
            'https://kindhand.helioho.st/kindhand-api/api/user/get_profile.php?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          final profileData = decodedResponse['data'];
          if (profileData['skills'] != null) {
            // Use the robust parsing logic
            return _parseSkills(profileData['skills']);
          }
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching skills for user $userId: $e');
      }
      return [];
    }
  }

  void _viewUserProfile(int userId, String userName) async {
    // Before navigating, pre-fetch the skills to ensure they're available
    try {
      final skills = await _fetchUserSkills(userId);
      if (kDebugMode) {
        print('Pre-fetched skills for user $userId: $skills');
      }

      // Store skills in the user data if possible
      for (var i = 0; i < _searchResults.length; i++) {
        if (_searchResults[i]['user_id'].toString() == userId.toString()) {
          setState(() {
            _searchResults[i]['skills'] = skills;
          });
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error pre-fetching skills: $e');
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewUserProfileScreen(
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCountry = null;
      _selectedVolunteerType = null;
      _locationController.clear();
      _searchController.clear();
    });
    _filterUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or bio',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF75B798)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF75B798)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: Color(0xFF75B798), width: 2),
                ),
              ),
              onChanged: (value) {
                _filterUsers();
              },
            ),
          ),

          // Filters Section
          if (_showFilters) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Location Filter
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Filter by location',
                      prefixIcon: const Icon(Icons.location_on,
                          color: Color(0xFF75B798)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF75B798)),
                      ),
                    ),
                    onChanged: (value) {
                      _filterUsers();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Dropdown Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Any Country'),
                            ),
                            ..._countries.map((country) {
                              return DropdownMenuItem(
                                value: country,
                                child: Text(country),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                            });
                            _filterUsers();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedVolunteerType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Any Type'),
                            ),
                            ..._volunteerTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedVolunteerType = value;
                            });
                            _filterUsers();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Clear Filters Button
                  ElevatedButton(
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Clear Filters'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],

          // Results count
          if (_hasSearched && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${_searchResults.length} users found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Loading Indicator
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF75B798)),
              ),
            ),

          // Error Message
          if (_errorMessage != null && !_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAllUsers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Search Results
          if (!_isLoading && _errorMessage == null)
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasSearched
                                ? 'No users found matching your criteria'
                                : 'Loading users...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final userId =
                            int.tryParse(user['user_id'].toString()) ?? 0;
                        final firstName = user['first_name'] ?? '';
                        final lastName = user['last_name'] ?? '';
                        final fullName = '$firstName $lastName'.trim();
                        final email = user['email'] ?? '';
                        final location = user['location'] ?? '';
                        final country = user['country'] ?? '';
                        final volunteerType = user['volunteer_type'] ?? '';
                        final bio = user['bio'] ?? '';
                        final userType = user['user_type'] ?? '';

                        // Parse skills using the robust method
                        final skills = _parseSkills(user['skills']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _viewUserProfile(userId, fullName),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Profile Avatar
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFF75B798),
                                    child: Text(
                                      firstName.isNotEmpty
                                          ? firstName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Name
                                        Text(
                                          fullName.isNotEmpty
                                              ? fullName
                                              : 'Unknown User',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Email
                                        if (email.isNotEmpty)
                                          Text(
                                            email,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),

                                        // Bio
                                        if (bio.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            bio,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],

                                        // Skills (if available)
                                        if (skills.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: skills
                                                .take(3)
                                                .map((skill) => Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF75B798)
                                                            .withValues(
                                                                alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        skill,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Color(0xFF75B798),
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ],

                                        // Location
                                        if (location.isNotEmpty ||
                                            country.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  [
                                                    if (location.isNotEmpty)
                                                      location,
                                                    if (country.isNotEmpty)
                                                      country,
                                                  ].join(', '),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],

                                        // Tags
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            // User Type
                                            if (userType.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF75B798)
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  userType,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF75B798),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                            // Volunteer Type
                                            if (volunteerType.isNotEmpty) ...[
                                              if (userType.isNotEmpty)
                                                const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  volunteerType,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Arrow Icon
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
