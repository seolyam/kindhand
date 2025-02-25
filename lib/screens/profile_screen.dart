import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> profileData = {
    'firstName': 'C2 na Red',
    'lastName': 'User',
    'email': 'c2nared@gmail.com',
    'country': 'Philippines',
    'volunteerType': 'Online',
    'skills': <String>[
      'UI/UX',
      'Videography',
      'Logo',
      'Graphic Design',
      'Figma'
    ],
    'education': <Map<String, String>>[
      {'school': 'University of St. La Salle', 'years': '2020-2026'}
    ],
    'bio':
        'Passionate volunteer dedicated to making a positive impact through online initiatives.',
    'location': 'Silay City, Western Visayas, Philippines',
    'badges': <Map<String, dynamic>>[
      {'icon': FeatherIcons.award, 'tooltip': 'Top Contributor'},
      {'icon': FeatherIcons.calendar, 'tooltip': 'Event Organizer'},
      {'icon': FeatherIcons.clock, 'tooltip': '100+ Hours'},
    ],
  };

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
                    "${profileData['firstName']} ${profileData['lastName']}",
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
    final skills = profileData['skills'] as List<String>? ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => _buildSkillChip(skill)).toList(),
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
    final education =
        profileData['education'] as List<Map<String, String>>? ?? [];
    return Column(
      children: education
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
    final badges = profileData['badges'] as List<Map<String, dynamic>>? ?? [];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges.map((badge) {
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
                badge['icon'] as IconData,
                color: const Color(0xFF75B798),
                size: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
