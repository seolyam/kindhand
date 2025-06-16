import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kindhand/screens/search_user_screen.dart';
import 'dart:async';
import 'view_user_profile_screen.dart';

class RealTimeSearchWidget extends StatefulWidget {
  const RealTimeSearchWidget({super.key});

  @override
  RealTimeSearchWidgetState createState() => RealTimeSearchWidgetState();
}

class RealTimeSearchWidgetState extends State<RealTimeSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
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
          'https://kindhand.helioho.st/kindhand-api/api/user/search_users.php?query=${Uri.encodeComponent(query)}&limit=10');

      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 3)); // Reduced timeout

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Search Results
        if (_showResults) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    itemCount:
                        _searchResults.length > 5 ? 5 : _searchResults.length,
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
                                  color:
                                      const Color(0xFF75B798).withOpacity(0.1),
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
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
