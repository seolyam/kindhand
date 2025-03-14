import 'package:flutter/material.dart';
import 'add_event_screen.dart';
import 'profile_screen.dart'; // Import your ProfileScreen
import 'volunteer_details_screen.dart';
import 'package:kindhand/services/event_service.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  MainFeedScreenState createState() => MainFeedScreenState();
}

class MainFeedScreenState extends State<MainFeedScreen> {
  List<Map<String, dynamic>> opportunities = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchOpportunities();
  }

  Future<void> _fetchOpportunities() async {
    try {
      final events = await EventService.getEvents();
      setState(() {
        // Initialize isBookmarked for all events
        for (var event in events) {
          event['isBookmarked'] = event['isBookmarked'] ?? false;
        }
        opportunities = events;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching events: $e')));
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Home - already on this screen.
        break;
      case 1:
        _navigateToSearch();
        break;
      case 2:
        _navigateToAddEvent();
        break;
      case 3:
        _navigateToSaved();
        break;
      case 4:
        _navigateToProfile();
        break;
    }
  }

  void _navigateToSearch() {
    // TODO: Implement navigation to Search screen
    print('Navigating to Search screen');
  }

  void _navigateToAddEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          onEventAdded: (Map<String, dynamic> newEvent) {
            setState(() {
              // Ensure isBookmarked is initialized
              newEvent['isBookmarked'] = false;
              opportunities.add(newEvent);
            });
          },
        ),
      ),
    );
  }

  void _navigateToSaved() {
    // TODO: Implement navigation to Saved screen
    print('Navigating to Saved screen');
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF75B798),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Search volunteers',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.filter_list, color: Colors.grey[600]),
                ],
              ),
            ),
            // Buttons Row (Preferences and Saved Volunteers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildPillButton('Preferences', true),
                  const SizedBox(width: 8),
                  _buildPillButton('Saved Volunteers', false),
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
                  const Text(
                    'Top picks for you',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on your profile, preferences, and volunteer like applies',
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
              child: opportunities.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF75B798),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: opportunities.length,
                      itemBuilder: (context, index) {
                        return _buildOpportunityCard(
                          context,
                          opportunities[index],
                          index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }

  Widget _buildPillButton(String text, bool isFilled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isFilled ? const Color(0xFF75B798) : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF75B798),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isFilled ? Colors.white : const Color(0xFF75B798),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(
      BuildContext context, Map<String, dynamic> opportunity, int index) {
    return GestureDetector(
      onTap: () {
        // Show details in a bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          barrierColor: Colors.black54,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => VolunteerDetailsScreen(
            opportunity: opportunity,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
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
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  opportunity['isBookmarked'] =
                      !(opportunity['isBookmarked'] ?? false);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
