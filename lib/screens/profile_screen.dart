import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'edit_profile_screen.dart';
import 'search_user_screen.dart';
import 'view_user_profile_screen.dart';
import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> profileData = {};
  bool _isLoading = true;
  String? errorMessage;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Real-time search variables
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _loadUserProfile();
    _searchFocusNode.addListener(() {
      setState(() {
        _showResults =
            _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Try to load profile data from cache first.
  Future<void> _loadCachedProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('profile_data');
    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(cachedData);
        setState(() {
          profileData = data;
          _isLoading = false;
        });
        if (kDebugMode) {
          print('Loaded cached profile data: $profileData');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error decoding cached profile data: $e');
        }
      }
    }
  }

  // Fetch profile data from service and update cache.
  Future<void> _loadUserProfile() async {
    try {
      final data = await UserProfileService.getUserProfile();
      setState(() {
        profileData = data;
        _isLoading = false;
        errorMessage = null;
      });
      if (kDebugMode) {
        print('Profile data loaded: $profileData');
      }
      // Cache the new data
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_data', json.encode(data));
    } catch (e) {
      setState(() {
        _isLoading = false;
        errorMessage = e.toString();
      });
      if (kDebugMode) {
        print('Error loading profile: $e');
      }
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userData: profileData,
          onSave: (updatedData) async {
            // Show loading indicator
            setState(() {
              _isLoading = true;
            });
            // Call the service to save to database
            final success =
                await UserProfileService.saveUserProfile(updatedData);
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              if (success) {
                _loadUserProfile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update profile')),
                  );
                }
              }
            }
          },
        ),
      ),
    );
    if (result != null) {
      _loadUserProfile(); // Reload profile data after editing
    }
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        // Focus the search field when showing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        // Clear search when hiding
        _searchController.clear();
        _searchFocusNode.unfocus();
        _clearSearch();
      }
    });
  }

  void _navigateToAdvancedSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchUserScreen(),
      ),
    );
  }

  // Real-time search functionality
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    if (query.length < 2) {
      setState(() {
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    try {
      final uri = Uri.parse(
          'https://kindhand.helioho.st/kindhand-api/api/user/search_users.php?query=${Uri.encodeComponent(query)}&limit=8');

      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 3));

      if (kDebugMode) {
        print('Search API Response: ${response.body}');
      }

      if (response.statusCode == 200 && mounted) {
        final decodedResponse = json.decode(response.body);

        List<Map<String, dynamic>> users = [];

        if (decodedResponse['success'] == true) {
          if (decodedResponse['data'] is Map &&
              decodedResponse['data']['data'] is List) {
            users = List<Map<String, dynamic>>.from(
                decodedResponse['data']['data']);
          } else if (decodedResponse['data'] is List) {
            users = List<Map<String, dynamic>>.from(decodedResponse['data']);
          }
        }

        setState(() {
          _searchResults = users;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Search error: $e');
      }
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _viewUserProfile(int userId, String userName) {
    // Hide keyboard and clear focus
    _searchFocusNode.unfocus();

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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showResults = false;
      _isSearching = false;
    });
  }

  /// Parse skills using the same robust logic as edit profile screen
  List<String> _parseSkills(dynamic skillsData) {
    try {
      if (skillsData == null) {
        return [];
      }

      if (kDebugMode) {
        print("Raw skills data in profile: $skillsData");
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Use both camelCase and snake_case keys to support different DB outputs.
    final firstName =
        profileData['firstName'] ?? profileData['first_name'] ?? '';
    final lastName = profileData['lastName'] ?? profileData['last_name'] ?? '';
    final bio = profileData['bio'] ?? '';
    final location = profileData['location'] ?? '';
    final country = profileData['country'] ?? '';

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar with Search
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Main App Bar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'User Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Search Icon Button
                            IconButton(
                              icon: Icon(
                                _showSearchBar ? Icons.close : Icons.search,
                                color: const Color(0xFF75B798),
                              ),
                              onPressed: _toggleSearchBar,
                              tooltip: 'Search Users',
                            ),
                          ],
                        ),

                        // Search Bar (shown when _showSearchBar is true)
                        if (_showSearchBar) ...[
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: _searchFocusNode.hasFocus
                                    ? const Color(0xFF75B798)
                                    : Colors.grey[300]!,
                                width: _searchFocusNode.hasFocus ? 2 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search users...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: _searchFocusNode.hasFocus
                                      ? const Color(0xFF75B798)
                                      : Colors.grey[600],
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: Icon(Icons.clear,
                                            color: Colors.grey[600]),
                                        onPressed: _clearSearch,
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.tune,
                                        color: Color(0xFF75B798),
                                        size: 20,
                                      ),
                                      onPressed: _navigateToAdvancedSearch,
                                      tooltip: 'Advanced Search',
                                    ),
                                  ],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Profile Header
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 120,
                          color: const Color(0xFF75B798),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 16,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFF75B798),
                          child: Text(
                            firstName.isNotEmpty && lastName.isNotEmpty
                                ? '${firstName[0]}${lastName[0]}'
                                : '?',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: _navigateToEditProfile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (bio.isNotEmpty) ...[
                        Text(
                          bio,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (location.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (country.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.flag,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              country,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildBadges(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _buildSection('Skills', _buildSkillChips()),
                _buildSection('Education', _buildEducationList()),
              ],
            ),
          ),

          // Search Results Overlay
          if (_showResults && _showSearchBar)
            Positioned(
              top: 140, // Adjust based on your app bar height
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF75B798),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Searching...'),
                          ],
                        ),
                      )
                    else if (_searchResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.search_off, color: Colors.grey[400]),
                            const SizedBox(width: 12),
                            Text(
                              'No users found for "${_searchController.text}"',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length > 5
                            ? 5
                            : _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
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
                          final userType = user['user_type'] ?? '';

                          return ListTile(
                            onTap: () => _viewUserProfile(userId, fullName),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF75B798),
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              fullName.isNotEmpty ? fullName : 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                if (location.isNotEmpty || country.isNotEmpty)
                                  Text(
                                    [
                                      if (location.isNotEmpty) location,
                                      if (country.isNotEmpty) country,
                                    ].join(', '),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (userType.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF75B798)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      userType,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF75B798),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Show more results option
                    if (_searchResults.length > 5)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchUserScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View all ${_searchResults.length} results',
                                style: const TextStyle(
                                  color: Color(0xFF75B798),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Color(0xFF75B798),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF75B798),
        unselectedItemColor: Colors.grey,
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildSkillChips() {
    // Use the robust skills parsing method
    final skillsList = _parseSkills(profileData['skills']);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skillsList.isEmpty
          ? [const Text('No skills added yet')]
          : skillsList.map((skill) => _buildSkillChip(skill)).toList(),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF75B798),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEducationList() {
    List<Map<String, dynamic>> educationList;
    if (profileData['education'] is String) {
      try {
        educationList = List<Map<String, dynamic>>.from(
            json.decode(profileData['education']));
      } catch (e) {
        if (kDebugMode) print('Error parsing education: $e');
        educationList = [];
      }
    } else if (profileData['education'] is List) {
      educationList = List<Map<String, dynamic>>.from(profileData['education']);
    } else {
      educationList = [];
    }

    return educationList.isEmpty
        ? const Text('No education added yet')
        : Column(
            children: educationList
                .map((edu) => ListTile(
                      leading:
                          const Icon(Icons.school, color: Color(0xFF75B798)),
                      title: Text(
                        edu['school'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      subtitle: Text(
                        edu['years'] ?? '',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ))
                .toList(),
          );
  }

  Widget _buildBadges() {
    List<Map<String, dynamic>> badgesList;
    if (profileData['badges'] is String) {
      try {
        badgesList =
            List<Map<String, dynamic>>.from(json.decode(profileData['badges']));
      } catch (e) {
        if (kDebugMode) print('Error parsing badges: $e');
        badgesList = [];
      }
    } else if (profileData['badges'] is List) {
      badgesList = List<Map<String, dynamic>>.from(profileData['badges']);
    } else {
      badgesList = [];
    }

    return badgesList.isEmpty
        ? const SizedBox.shrink()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: badgesList.map((badge) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: badge['tooltip'] as String? ?? '',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF75B798).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF75B798)),
                    ),
                    child: Icon(
                      _getIconData(badge['icon'] as String? ?? 'award'),
                      color: const Color(0xFF75B798),
                      size: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'award':
        return FeatherIcons.award;
      case 'calendar':
        return FeatherIcons.calendar;
      case 'clock':
        return FeatherIcons.clock;
      default:
        return FeatherIcons.award;
    }
  }
}
