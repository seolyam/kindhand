import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'edit_profile_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

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
            setState(() {
              _isLoading = false;
            });
            if (success) {
              _loadUserProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to update profile')),
              );
            }
          },
        ),
      ),
    );
    if (result != null) {
      _loadUserProfile(); // Reload profile data after editing
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

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
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
                    const SizedBox(width: 48),
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
                    child: const CircleAvatar(
                      radius: 56,
                      backgroundColor: Color(0xFF75B798),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
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
                    "${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileData['bio'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileData['location'] ?? '',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
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
    List<String> skillsList;
    // Check if profileData['skills'] is a String or already a List
    if (profileData['skills'] is String) {
      try {
        skillsList = List<String>.from(json.decode(profileData['skills']));
      } catch (e) {
        if (kDebugMode) print('Error parsing skills: $e');
        skillsList = [];
      }
    } else if (profileData['skills'] is List) {
      skillsList = List<String>.from(profileData['skills']);
    } else {
      skillsList = [];
    }
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
