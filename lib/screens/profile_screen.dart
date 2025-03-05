import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'dart:convert';
import 'edit_profile_screen.dart';
import '../services/user_profile_service.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> profileData = {};
  bool isLoading = true;
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
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
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
          onSave: (updatedData) {
            setState(() {
              profileData = updatedData;
            });
          },
        ),
      ),
    );
    if (result != null) {
      setState(() {
        profileData = Map<String, dynamic>.from(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
                    "${profileData['first_name']} ${profileData['last_name']}",
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
    final skills = (profileData['skills'] as String? ?? '[]');
    List<String> skillsList = List<String>.from(json.decode(skills));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skillsList.map((skill) => _buildSkillChip(skill)).toList(),
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
    final education = (profileData['education'] as String? ?? '[]');
    List<Map<String, dynamic>> educationList =
        List<Map<String, dynamic>>.from(json.decode(education));
    return Column(
      children: educationList
          .map((edu) => ListTile(
                leading: const Icon(Icons.school, color: Color(0xFF75B798)),
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
    final badges = (profileData['badges'] as String? ?? '[]');
    List<Map<String, dynamic>> badgesList =
        List<Map<String, dynamic>>.from(json.decode(badges));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badgesList.map((badge) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Tooltip(
            message: badge['tooltip'] as String,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF75B798).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF75B798)),
              ),
              child: Icon(
                _getIconData(badge['icon']),
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
