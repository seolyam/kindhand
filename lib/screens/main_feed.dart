import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_event_screen.dart';
import 'profile_screen.dart';
import 'event_details_screen.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'event_applicants_screen.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  MainFeedScreenState createState() => MainFeedScreenState();
}

class MainFeedScreenState extends State<MainFeedScreen> {
  List<Map<String, dynamic>> allOpportunities = [];
  List<Map<String, dynamic>> filteredOpportunities = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _showSavedOnly = false;
  String _searchQuery = '';
  String _userType = 'volunteer'; // Default to volunteer
  String? _userId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool enableDebugLogs = false; // Set to false to disable logs

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchOpportunities();
  }

  void logDebug(String message) {
    if (kDebugMode && enableDebugLogs) {
      print(message);
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final userId = prefs.getString('user_id');

      // Debug all SharedPreferences values
      if (kDebugMode && enableDebugLogs) {
        logDebug('ALL SHARED PREFERENCES:');
        logDebug('user_id: ${prefs.getString('user_id')}');
        logDebug('user_email: ${prefs.getString('user_email')}');
        logDebug('user_type: ${prefs.getString('user_type')}');

        // Check if userType is exactly 'organization' with no extra spaces
        if (userType != null) {
          logDebug('USER TYPE LENGTH: ${userType.length}');
          logDebug('USER TYPE BYTES: ${userType.codeUnits}');
          logDebug('IS EXACTLY "organization": ${userType == 'organization'}');
        }
      }

      if (mounted) {
        setState(() {
          // If userType is null or empty, default to 'volunteer'
          _userType = (userType != null && userType.isNotEmpty)
              ? userType.trim() // Trim any whitespace
              : 'volunteer';
          _userId = userId;
        });

        if (kDebugMode && enableDebugLogs) {
          logDebug('CURRENT USER TYPE SET TO: $_userType');
          logDebug('IS ORGANIZATION: ${_userType == 'organization'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user info: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchOpportunities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await EventService.getEvents();

      if (mounted) {
        setState(() {
          // Initialize isBookmarked for all events
          for (var event in events) {
            event['isBookmarked'] = event['isBookmarked'] ?? false;
          }
          allOpportunities = events;
          _filterOpportunities();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching events: $e')));
      }
    }
  }

  void _filterOpportunities() {
    setState(() {
      if (_searchQuery.isEmpty && !_showSavedOnly) {
        filteredOpportunities = List.from(allOpportunities);
      } else {
        filteredOpportunities = allOpportunities.where((opportunity) {
          // Filter by search query
          final matchesSearch = _searchQuery.isEmpty ||
              (opportunity['title']
                      ?.toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false) ||
              (opportunity['description']
                      ?.toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false) ||
              (opportunity['location']
                      ?.toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false);

          // Filter by saved status
          final matchesSaved =
              !_showSavedOnly || opportunity['isBookmarked'] == true;

          return matchesSearch && matchesSaved;
        }).toList();
      }
    });
  }

  void _onItemTapped(int index) {
    logDebug('Item tapped: $index, User type: $_userType');

    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0: // Home
        // Already on home screen
        break;
      case 1: // Search
        _toggleSearch();
        break;
      case 2:
        // For organization users, this is the Add button
        // For volunteer users, this is the Saved button
        if (_userType.toLowerCase() == 'organization') {
          _navigateToAddEvent();
        } else {
          _toggleSavedFilter();
        }
        break;
      case 3:
        // For organization users, this is the Saved button
        // For volunteer users, this is the Profile button
        if (_userType.toLowerCase() == 'organization') {
          _toggleSavedFilter();
        } else {
          _navigateToProfile();
        }
        break;
      case 4: // Profile (only for organization users)
        if (_userType.toLowerCase() == 'organization') {
          _navigateToProfile();
        }
        break;
    }
  }

  void _toggleSearch() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    } else {
      _searchFocusNode.requestFocus();
    }
  }

  void _toggleSavedFilter() {
    setState(() {
      _showSavedOnly = !_showSavedOnly;
      _filterOpportunities();
    });
  }

  void _navigateToAddEvent() {
    logDebug('Navigating to Add Event Screen');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          onEventAdded: (Map<String, dynamic> newEvent) {
            setState(() {
              // Ensure isBookmarked is initialized
              newEvent['isBookmarked'] = false;
              allOpportunities.add(newEvent);
              _filterOpportunities();
            });
          },
        ),
      ),
    ).then((_) {
      // Refresh user type when returning from other screens
      _refreshUserType();
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      // Refresh user type when returning from profile screen
      _refreshUserType();
    });
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Refresh user type from SharedPreferences only when needed
  Future<void> _refreshUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');

      logDebug('REFRESHING USER TYPE: $userType');

      if (mounted && userType != null) {
        // Only update state if user type has changed
        if (userType.trim() != _userType) {
          setState(() {
            _userType = userType.trim();
          });
          logDebug('USER TYPE UPDATED TO: $_userType');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing user type: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    logDebug('BUILDING SCREEN WITH USER TYPE: $_userType');
    logDebug('SHOULD SHOW FAB: ${_userType == 'organization'}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF75B798),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search events',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _filterOpportunities();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      // Show filter options
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => _buildFilterOptions(),
                      );
                    },
                    child: Icon(Icons.filter_list, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Buttons Row (Preferences and Saved Volunteers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildPillButton('All Events', !_showSavedOnly, () {
                    setState(() {
                      _showSavedOnly = false;
                      _filterOpportunities();
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildPillButton('Saved Events', _showSavedOnly, () {
                    setState(() {
                      _showSavedOnly = true;
                      _filterOpportunities();
                    });
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Top Picks Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userType.toLowerCase() == 'organization'
                        ? 'Your Events'
                        : 'Events for you',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Search results for "$_searchQuery"'
                        : _userType.toLowerCase() == 'organization'
                            ? 'Manage and track your volunteer events'
                            : 'Based on your profile and preferences',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Opportunities List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF75B798),
                      ),
                    )
                  : filteredOpportunities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.event_busy,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No events found for "$_searchQuery"'
                                    : _showSavedOnly
                                        ? 'No saved events yet'
                                        : _userType == 'organization'
                                            ? 'You haven\'t created any events yet'
                                            : 'No events available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              if (_searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _filterOpportunities();
                                    });
                                  },
                                  child: const Text('Clear Search'),
                                )
                              else if (_userType == 'organization')
                                ElevatedButton.icon(
                                  onPressed: _navigateToAddEvent,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Event'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF75B798),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchOpportunities,
                          color: const Color(0xFF75B798),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredOpportunities.length,
                            itemBuilder: (context, index) {
                              return _buildOpportunityCard(
                                context,
                                filteredOpportunities[index],
                                index,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
      // FAB for organizations to quickly add events
      floatingActionButton: _userType.toLowerCase() == 'organization'
          ? FloatingActionButton(
              onPressed: _navigateToAddEvent,
              backgroundColor: const Color(0xFF75B798),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    logDebug('BUILDING NAVBAR WITH USER TYPE: $_userType');

    // Different navigation items based on user type
    if (_userType.toLowerCase() == 'organization') {
      // Organization navigation items
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF75B798),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      );
    } else {
      // Volunteer navigation items (no add button)
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF75B798),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      );
    }
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Remote Events Only'),
            value: false, // Replace with actual filter state
            onChanged: (value) {
              // Implement filter logic
              Navigator.pop(context);
            },
            activeColor: const Color(0xFF75B798),
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear All Filters'),
            leading: const Icon(Icons.clear_all),
            onTap: () {
              // Clear all filters
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF75B798),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF75B798) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF75B798),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF75B798),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(
      BuildContext context, Map<String, dynamic> opportunity, int index) {
    // Format creator name
    String creatorName = "Unknown";
    if (opportunity['first_name'] != null && opportunity['last_name'] != null) {
      creatorName = "${opportunity['first_name']} ${opportunity['last_name']}";
    }

    // Check if this event was created by the current user
    final isCreatedByCurrentUser =
        _userId != null && opportunity['created_by']?.toString() == _userId;

    return GestureDetector(
      onTap: () {
        // Show details in a bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => EventDetailsScreen(
            event: opportunity,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          // Highlight events created by the current user (for organizations)
          color: _userType.toLowerCase() == 'organization' &&
                  isCreatedByCurrentUser
              ? const Color(0xFFE8F5E9)
              : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF75B798),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opportunity['location'] ?? 'No Location',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    opportunity['isBookmarked'] == true
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: opportunity['isBookmarked'] == true
                        ? const Color(0xFF75B798)
                        : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      opportunity['isBookmarked'] =
                          !(opportunity['isBookmarked'] ?? false);
                      // If we're showing saved only, we need to update the filtered list
                      if (_showSavedOnly) {
                        _filterOpportunities();
                      }
                    });
                  },
                ),
                // Add a View Applicants button for organization users if they created this event
                if (_userType.toLowerCase() == 'organization' &&
                    isCreatedByCurrentUser)
                  IconButton(
                    icon: const Icon(
                      Icons.people,
                      color: Color(0xFF75B798),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventApplicantsScreen(
                            event: opportunity,
                          ),
                        ),
                      );
                    },
                    tooltip: 'View Applicants',
                  ),
              ],
            ),
            if (opportunity['description'] != null &&
                opportunity['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  opportunity['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (opportunity['is_remote'] == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1E7DD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Remote',
                        style: TextStyle(
                          color: Color(0xFF75B798),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    isCreatedByCurrentUser
                        ? 'Created by you'
                        : 'Created by: $creatorName',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
