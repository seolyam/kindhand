import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/user_profile_service.dart';
import '../services/application_service.dart';
import 'package:http/http.dart' as http;

class ViewUserProfileScreen extends StatefulWidget {
  final int userId;
  final String? userName;
  final int? eventId; // Optional: to show application status for this event

  const ViewUserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
    this.eventId,
  });

  @override
  ViewUserProfileScreenState createState() => ViewUserProfileScreenState();
}

class ViewUserProfileScreenState extends State<ViewUserProfileScreen> {
  Map<String, dynamic> profileData = {};
  Map<String, dynamic> applicationStatus = {};
  List<Map<String, dynamic>> volunteerHistory = [];
  bool _isLoading = true;
  bool _isLoadingHistory = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    if (widget.eventId != null) {
      _loadApplicationStatus();
    }
    _loadVolunteerHistory();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        errorMessage = null;
      });

      final data = await UserProfileService.getOtherUserProfile(widget.userId);

      // If skills are empty, try to fetch them directly from the profile API
      if ((data['skills'] == null ||
              (data['skills'] is List && data['skills'].isEmpty)) &&
          mounted) {
        try {
          if (kDebugMode) {
            print(
                'Skills are empty, trying to fetch directly from profile API');
          }

          final response = await http.get(
            Uri.parse(
                'https://kindhand.helioho.st/kindhand-api/api/user/get_profile.php?user_id=${widget.userId}'),
            headers: {"Content-Type": "application/json"},
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            final decodedResponse = json.decode(response.body);
            if (decodedResponse['success'] == true) {
              final profileData = decodedResponse['data'];
              if (profileData['skills'] != null) {
                data['skills'] = profileData['skills'];
                if (kDebugMode) {
                  print(
                      'Successfully fetched skills directly: ${profileData['skills']}');
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching skills directly: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          profileData = data;
          _isLoading = false;
          errorMessage = null;
        });

        if (kDebugMode) {
          print(
              'Profile data loaded successfully: ${data['firstName']} ${data['lastName']}');
          print('Skills data: ${data['skills']}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          errorMessage = 'Unable to load profile. Please try again.';
        });

        if (kDebugMode) {
          print('Error loading profile: $e');
        }
      }
    }
  }

  Future<void> _loadApplicationStatus() async {
    try {
      final status = await ApplicationService.checkApplicationStatusForUser(
        eventId: widget.eventId!,
        userId: widget.userId,
      );
      setState(() {
        applicationStatus = status;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading application status: $e');
      }
    }
  }

  Future<void> _loadVolunteerHistory() async {
    try {
      final history =
          await ApplicationService.getUserVolunteerHistory(widget.userId);
      setState(() {
        volunteerHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      if (kDebugMode) {
        print('Error loading volunteer history: $e');
      }
    }
  }

  /// Parse skills using the same robust logic as edit profile screen
  List<String> _parseSkills(dynamic skillsData) {
    try {
      if (skillsData == null) {
        return [];
      }

      if (kDebugMode) {
        print("Raw skills data in profile view: $skillsData");
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
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName != null
              ? '${widget.userName}\'s Profile'
              : 'User Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF75B798))),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName != null
              ? '${widget.userName}\'s Profile'
              : 'User Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Could not load user profile. The server may be experiencing issues.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF75B798),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Use both camelCase and snake_case keys to support different DB outputs
    final firstName =
        profileData['firstName'] ?? profileData['first_name'] ?? '';
    final lastName = profileData['lastName'] ?? profileData['last_name'] ?? '';
    final bio = profileData['bio'] ?? '';
    final location = profileData['location'] ?? '';
    final email = profileData['email'] ?? '';
    final volunteerType =
        profileData['volunteerType'] ?? profileData['volunteer_type'] ?? '';
    final country = profileData['country'] ?? '';

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
                    Expanded(
                      child: Text(
                        widget.userName != null
                            ? '${widget.userName}\'s Profile'
                            : 'User Profile',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
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
                        const Icon(Icons.flag, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          country,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (volunteerType.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.volunteer_activism,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Volunteer Type: $volunteerType',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildBadges(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Application Status (if viewing from an event)
            if (widget.eventId != null && applicationStatus.isNotEmpty) ...[
              _buildSection('Application Status', _buildApplicationStatus()),
            ],

            _buildSection('Skills', _buildSkillChips()),
            _buildSection('Education', _buildEducationList()),

            // Only show volunteer history section if there's actual history
            if (volunteerHistory.isNotEmpty)
              _buildSection('Volunteer History', _buildVolunteerHistory()),

            _buildSection('Contact Information', _buildContactInfo(email)),
            const SizedBox(height: 40),
          ],
        ),
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

  Widget _buildApplicationStatus() {
    if (applicationStatus.isEmpty) {
      return const Text('No application information available');
    }

    final hasVolunteer =
        applicationStatus['has_volunteer_application'] ?? false;
    final hasInterested =
        applicationStatus['has_interested_application'] ?? false;
    final volunteerStatus = applicationStatus['volunteer_status'];
    final interestedStatus = applicationStatus['interested_status'];

    if (!hasVolunteer && !hasInterested) {
      return const Text('No applications submitted for this event');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVolunteer) ...[
          _buildStatusItem(
            'Volunteer',
            volunteerStatus ?? 'unknown',
            Icons.volunteer_activism,
          ),
        ],
        if (hasInterested) ...[
          const SizedBox(height: 8),
          _buildStatusItem(
            'Interested',
            interestedStatus ?? 'unknown',
            Icons.favorite,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusItem(String type, String status, IconData icon) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, color: const Color(0xFF75B798), size: 20),
        const SizedBox(width: 12),
        Text(
          type,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.substring(0, 1).toUpperCase() + status.substring(1),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChips() {
    // Use the robust skills parsing method
    final skillsList = _parseSkills(profileData['skills']);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skillsList.isEmpty
          ? [
              const Text('No skills added yet',
                  style: TextStyle(color: Colors.grey))
            ]
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

  Widget _buildVolunteerHistory() {
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Color(0xFF75B798)),
        ),
      );
    }

    if (volunteerHistory.isEmpty) {
      return const Text('No volunteer history available');
    }

    return Column(
      children: volunteerHistory.map((event) {
        final String eventTitle = event['event_title'] ?? 'Unknown Event';
        final String status = event['status'] ?? 'unknown';
        String eventDate = 'Unknown date';

        if (event['event_date'] != null) {
          try {
            final DateTime date = DateTime.parse(event['event_date']);
            eventDate = DateFormat('MMMM d, yyyy').format(date);
          } catch (e) {
            if (kDebugMode) print('Error parsing date: $e');
          }
        }

        Color statusColor;
        switch (status.toLowerCase()) {
          case 'approved':
            statusColor = Colors.green;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          case 'pending':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.event,
                color: Color(0xFF75B798),
                size: 24,
              ),
            ),
            title: Text(
              eventTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(eventDate),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.substring(0, 1).toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactInfo(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (email.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.email, color: Color(0xFF75B798)),
            title: Text(email),
          ),
      ],
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
