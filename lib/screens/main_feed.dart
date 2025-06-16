import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_event_screen.dart';
import 'profile_screen.dart';
import 'event_details_screen.dart';
import '../services/event_service.dart';
import 'event_applicants_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart';

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
  String _currentFilter = 'all'; // 'all', 'saved', 'yours'
  String _searchQuery = '';
  String _userType = 'volunteer'; // Default to volunteer
  String? _userId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool enableDebugLogs = false; // Set to false to disable logs
  Timer? _debounceTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchOpportunities();
  }

  void _logDebug(String message) {
    if (kDebugMode && enableDebugLogs) {
      debugPrint('[MainFeedScreen] $message');
    }
  }

  void _logError(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint(
          '[MainFeedScreen ERROR] $message${error != null ? ': $error' : ''}');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final userId = prefs.getString('user_id');

      // Debug all SharedPreferences values
      if (kDebugMode && enableDebugLogs) {
        _logDebug('ALL SHARED PREFERENCES:');
        _logDebug('user_id: ${prefs.getString('user_id')}');
        _logDebug('user_email: ${prefs.getString('user_email')}');
        _logDebug('user_type: ${prefs.getString('user_type')}');

        // Check if userType is exactly 'organization' with no extra spaces
        if (userType != null) {
          _logDebug('USER TYPE LENGTH: ${userType.length}');
          _logDebug('USER TYPE BYTES: ${userType.codeUnits}');
          _logDebug('IS EXACTLY "organization": ${userType == 'organization'}');
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
          _logDebug('CURRENT USER TYPE SET TO: $_userType');
          _logDebug('IS ORGANIZATION: ${_userType == 'organization'}');
        }
      }
    } catch (e) {
      _logError('Error loading user info', e);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOpportunities() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous requests

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      final events = await EventService.getEvents();

      if (mounted) {
        // Process data in chunks to avoid blocking the main thread
        final processedEvents = <Map<String, dynamic>>[];

        for (int i = 0; i < events.length; i += 10) {
          final chunk = events.skip(i).take(10);
          for (var event in chunk) {
            event['isBookmarked'] = event['isBookmarked'] ?? false;
            processedEvents.add(event);
          }

          // Yield control back to the main thread every 10 items
          if (i + 10 < events.length) {
            await Future.delayed(Duration.zero);
          }
        }

        if (mounted) {
          setState(() {
            allOpportunities = processedEvents;
            _filterOpportunities();
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      _logError('Error fetching events', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching events: $e')));
      }
    }
  }

  void _filterOpportunities() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      final filtered = <Map<String, dynamic>>[];
      final searchLower = _searchQuery.toLowerCase();

      for (final opportunity in allOpportunities) {
        // Filter by type first
        bool matchesFilter = false;
        switch (_currentFilter) {
          case 'all':
            matchesFilter = true;
            break;
          case 'saved':
            matchesFilter = opportunity['isBookmarked'] == true;
            break;
          case 'yours':
            matchesFilter = _userId != null &&
                opportunity['created_by']?.toString() == _userId;
            break;
        }

        if (!matchesFilter) continue;

        // Then filter by search query
        if (_searchQuery.isNotEmpty) {
          final titleLower =
              opportunity['title']?.toString().toLowerCase() ?? '';
          final descriptionLower =
              opportunity['description']?.toString().toLowerCase() ?? '';
          final locationLower =
              opportunity['location']?.toString().toLowerCase() ?? '';

          if (!titleLower.contains(searchLower) &&
              !descriptionLower.contains(searchLower) &&
              !locationLower.contains(searchLower)) {
            continue;
          }
        }

        filtered.add(opportunity);
      }

      if (mounted) {
        setState(() {
          filteredOpportunities = filtered;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    _logDebug('Item tapped: $index, User type: $_userType');

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
      case 2: // Saved
        _toggleSavedFilter();
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
      if (_currentFilter == 'saved') {
        _currentFilter = 'all';
      } else {
        _currentFilter = 'saved';
      }
      _filterOpportunities();
    });
  }

  void _navigateToAddEvent() {
    _logDebug('Navigating to Add Event Screen');

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
    HapticFeedback.lightImpact(); // Add haptic feedback
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      // Refresh user type when returning from profile screen
      _refreshUserType();
    });
  }

  // Refresh user type from SharedPreferences only when needed
  Future<void> _refreshUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');

      _logDebug('REFRESHING USER TYPE: $userType');

      if (mounted && userType != null) {
        // Only update state if user type has changed
        if (userType.trim() != _userType) {
          setState(() {
            _userType = userType.trim();
          });
          _logDebug('USER TYPE UPDATED TO: $_userType');
        }
      }
    } catch (e) {
      _logError('Error refreshing user type', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logDebug('BUILDING SCREEN WITH USER TYPE: $_userType');
    _logDebug('SHOULD SHOW FAB: ${_userType == 'organization'}');

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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _navigateToProfile,
                      borderRadius: BorderRadius.circular(20),
                      splashColor: const Color(0xFF75B798).withOpacity(0.2),
                      highlightColor: const Color(0xFF75B798).withOpacity(0.1),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF75B798),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF75B798).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
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
                          _searchQuery =
                              value; // Update immediately for UI responsiveness
                          _filterOpportunities(); // This now includes debouncing
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
            _buildFilterButtons(),
            const SizedBox(height: 24),
            // Top Picks Section
            _buildTitleSection(),
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
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchOpportunities,
                          color: const Color(0xFF75B798),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredOpportunities.length,
                            // Add these performance optimizations
                            cacheExtent: 500, // Cache items outside viewport
                            addAutomaticKeepAlives:
                                false, // Don't keep items alive unnecessarily
                            addRepaintBoundaries:
                                false, // Reduce repaint boundaries for simple items
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
    _logDebug('BUILDING NAVBAR WITH USER TYPE: $_userType');

    // Different navigation items based on user type
    if (_userType.toLowerCase() == 'organization') {
      // Organization navigation items - removed the Add button
      return BottomNavigationBar(
        currentIndex: _selectedIndex, // Adjust selected index
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
        ],
      );
    } else {
      // Volunteer navigation items (unchanged)
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
                      _filterOpportunities();
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

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPillButton('All Events', _currentFilter == 'all', () {
              setState(() {
                _currentFilter = 'all';
                _filterOpportunities();
              });
            }),
            const SizedBox(width: 8),
            _buildPillButton('Saved Events', _currentFilter == 'saved', () {
              setState(() {
                _currentFilter = 'saved';
                _filterOpportunities();
              });
            }),
            const SizedBox(width: 8),
            _buildPillButton('Your Events', _currentFilter == 'yours', () {
              setState(() {
                _currentFilter = 'yours';
                _filterOpportunities();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    String title;
    String subtitle;

    if (_searchQuery.isNotEmpty) {
      title = 'Search Results';
      subtitle = 'Results for "$_searchQuery"';
    } else {
      switch (_currentFilter) {
        case 'all':
          title = 'All Events';
          subtitle = _userType.toLowerCase() == 'organization'
              ? 'All volunteer events in the platform'
              : 'Discover volunteer opportunities';
          break;
        case 'saved':
          title = 'Saved Events';
          subtitle = 'Events you\'ve bookmarked for later';
          break;
        case 'yours':
          title = 'Your Events';
          subtitle = _userType.toLowerCase() == 'organization'
              ? 'Events you\'ve created and manage'
              : 'Events you\'ve created';
          break;
        default:
          title = 'Events';
          subtitle = 'Volunteer opportunities';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage;
    String actionText = '';
    VoidCallback? actionCallback;

    if (_searchQuery.isNotEmpty) {
      emptyMessage = 'No events found for "$_searchQuery"';
      actionText = 'Clear Search';
      actionCallback = () {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          _filterOpportunities();
        });
      };
    } else {
      switch (_currentFilter) {
        case 'all':
          emptyMessage = 'No events available at the moment';
          if (_userType == 'organization') {
            actionText = 'Create Event';
            actionCallback = _navigateToAddEvent;
          }
          break;
        case 'saved':
          emptyMessage = 'No saved events yet';
          break;
        case 'yours':
          emptyMessage = _userType == 'organization'
              ? 'You haven\'t created any events yet'
              : 'You haven\'t created any events yet';
          if (_userType == 'organization') {
            actionText = 'Create Your First Event';
            actionCallback = _navigateToAddEvent;
          }
          break;
        default:
          emptyMessage = 'No events available';
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off
                : _currentFilter == 'yours'
                    ? Icons.event_note
                    : _currentFilter == 'saved'
                        ? Icons.bookmark_border
                        : Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (actionText.isNotEmpty && actionCallback != null)
            ElevatedButton.icon(
              onPressed: actionCallback,
              icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.add),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF75B798),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
