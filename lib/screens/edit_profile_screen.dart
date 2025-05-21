import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _schoolController;
  String _selectedCountry = 'Philippines';
  // Default dropdown items for volunteer type
  final List<String> _volunteerTypes = ['Online', 'On-site', 'Hybrid'];
  String _selectedVolunteerType = 'Online';
  List<String> _skills = [];
  List<Map<String, String>> _education = [];
  bool _isLoading = true;
  Map<String, dynamic> _cachedUserData = {};

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  // Load data from SharedPreferences first, then merge with widget.userData
  Future<void> _loadCachedData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get cached data from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString('user_profile_data');

      if (cachedData != null) {
        // Parse cached data
        _cachedUserData = json.decode(cachedData);
        if (kDebugMode) {
          print("Loaded cached user data: $_cachedUserData");
        }
      }

      // Merge cached data with widget.userData, prioritizing widget.userData
      Map<String, dynamic> mergedData = {
        ..._cachedUserData,
        ...widget.userData
      };

      // Initialize controllers with merged data
      _initializeControllers(mergedData);

      // Cache the merged data for future use
      await _cacheUserData(mergedData);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached data: $e');
      }
      // Fall back to widget.userData if there's an error
      _initializeControllers(widget.userData);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Cache user data to SharedPreferences
  Future<void> _cacheUserData(Map<String, dynamic> data) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_data', json.encode(data));
      if (kDebugMode) {
        print("Cached user data: $data");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching user data: $e');
      }
    }
  }

  void _initializeControllers(Map<String, dynamic> data) {
    // Handle different field naming conventions (camelCase vs snake_case)
    _firstNameController = TextEditingController(
      text: data['firstName'] ?? data['first_name'] ?? '',
    );

    _lastNameController = TextEditingController(
      text: data['lastName'] ?? data['last_name'] ?? '',
    );

    _emailController = TextEditingController(
      text: data['email'] ?? '',
    );

    _bioController = TextEditingController(
      text: data['bio'] ?? '',
    );

    _locationController = TextEditingController(
      text: data['location'] ?? '',
    );

    _selectedCountry = data['country'] ?? 'Philippines';

    // Get volunteer type from data; if not one of allowed types, default to 'Online'
    String volunteerType =
        data['volunteerType'] ?? data['volunteer_type'] ?? 'Online';
    if (!_volunteerTypes.contains(volunteerType)) {
      volunteerType = 'Online';
    }
    _selectedVolunteerType = volunteerType;

    // Parse skills
    _parseSkills(data);

    // Parse education
    _parseEducation(data);

    // Initialize school controller based on education data
    if (_education.isNotEmpty && _education[0].containsKey('school')) {
      _schoolController = TextEditingController(text: _education[0]['school']);
    } else {
      _schoolController =
          TextEditingController(text: 'University of St. La Salle');
      // Add default education if none exists
      if (_education.isEmpty) {
        _education.add({'school': 'University of St. La Salle'});
      }
    }
  }

  void _parseSkills(Map<String, dynamic> data) {
    try {
      if (data['skills'] != null) {
        dynamic skillsData = data['skills'];

        if (kDebugMode) {
          print("Raw skills data: $skillsData");
          print("Skills data type: ${skillsData.runtimeType}");
        }

        if (skillsData is String) {
          // Handle empty arrays
          if (skillsData == "[]" || skillsData == "\"[]\"") {
            _skills = [];
            return;
          }

          // Remove outer quotes if present (handles double encoding)
          if (skillsData.startsWith('"') && skillsData.endsWith('"')) {
            skillsData = skillsData.substring(1, skillsData.length - 1);
            // Unescape inner quotes
            skillsData = skillsData.replaceAll('\\"', '"');
          }

          try {
            dynamic decoded = jsonDecode(skillsData);
            if (decoded is List) {
              _skills =
                  List<String>.from(decoded.map((item) => item.toString()));
            } else {
              _skills = [];
            }
          } catch (e) {
            if (kDebugMode) print("Skills JSON parse error: $e");
            // If parsing fails, use as a single skill if it's not empty
            if (skillsData.isNotEmpty && skillsData != "[]") {
              _skills = [skillsData];
            } else {
              _skills = [];
            }
          }
        } else if (skillsData is List) {
          _skills =
              List<String>.from(skillsData.map((item) => item.toString()));
        } else {
          _skills = [];
        }

        if (kDebugMode) print("Final parsed skills: $_skills");
      } else {
        _skills = [];
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing skills: $e');
      _skills = [];
    }
  }

  void _parseEducation(Map<String, dynamic> data) {
    try {
      if (data['education'] != null) {
        dynamic educationData = data['education'];

        if (kDebugMode) {
          print("Raw education data: $educationData");
          print("Education data type: ${educationData.runtimeType}");
        }

        if (educationData is String) {
          // Handle empty arrays
          if (educationData == "[]" || educationData == "\"[]\"") {
            _education = [];
            return;
          }

          // Remove outer quotes if present (handles double encoding)
          if (educationData.startsWith('"') && educationData.endsWith('"')) {
            educationData =
                educationData.substring(1, educationData.length - 1);
            // Unescape inner quotes
            educationData = educationData.replaceAll('\\"', '"');
          }

          try {
            dynamic decoded = jsonDecode(educationData);
            if (decoded is List) {
              if (decoded.isEmpty) {
                _education = [];
              } else {
                _education = List<Map<String, String>>.from(
                  decoded.map((item) => item is Map
                      ? Map<String, String>.from(item.map((key, value) =>
                          MapEntry(key.toString(), value.toString())))
                      : {'school': item.toString()}),
                );
              }
            } else if (decoded is Map) {
              _education = [
                Map<String, String>.from(decoded.map(
                    (key, value) => MapEntry(key.toString(), value.toString())))
              ];
            } else {
              _education = [];
            }
          } catch (e) {
            if (kDebugMode) print("Education JSON parse error: $e");
            _education = [];
          }
        } else if (educationData is List) {
          if (educationData.isEmpty) {
            _education = [];
          } else {
            _education = List<Map<String, String>>.from(
              educationData.map((item) => item is Map
                  ? Map<String, String>.from(item.map((key, value) =>
                      MapEntry(key.toString(), value.toString())))
                  : {'school': item.toString()}),
            );
          }
        } else {
          _education = [];
        }

        if (kDebugMode) print("Final parsed education: $_education");
      } else {
        _education = [];
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing education: $e');
      _education = [];
    }
  }

  Future<void> _logout() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted && kDebugMode) {
        print('Logout error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred during logout: $e')),
        );
      }
    }
  }

  void _addSkill() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Skill'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter skill',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _skills.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _addEducation() {
    showDialog(
      context: context,
      builder: (context) {
        final schoolController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Education'),
          content: TextField(
            controller: schoolController,
            decoration: const InputDecoration(
              hintText: 'School name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (schoolController.text.isNotEmpty) {
                  setState(() {
                    _education.add({'school': schoolController.text});
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Remove education at a specific index
  void _removeEducation(int index) {
    if (_education.length > 1) {
      // Always keep at least one education entry
      setState(() {
        _education.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must have at least one education entry')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saving profile...')),
        );

        // Create updated data including bio and location
        final updatedData = {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'bio': _bioController.text,
          'location': _locationController.text,
          'country': _selectedCountry,
          'volunteerType': _selectedVolunteerType,
          'skills': _skills,
          'education': _education,
        };

        // Save to database through onSave callback
        await widget.onSave(updatedData);

        // Update cached data
        await _cacheUserData(updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context, updatedData);
        }
      } catch (e) {
        if (mounted && kDebugMode) {
          print('Save profile error: $e');
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5CB89E),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                child: const Text(
                  '* indicates required',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              _buildFormField('First name*', _firstNameController),
              _buildFormField('Last name*', _lastNameController),
              _buildFormField('Email address', _emailController),
              _buildFormField('Bio', _bioController),
              _buildFormField('Location', _locationController),
              _buildDropdownField(
                'Country/Region*',
                _selectedCountry,
                ['Philippines', 'United States', 'Canada', 'Other'],
                (value) => setState(() => _selectedCountry = value!),
              ),
              _buildDropdownField(
                'Preferred volunteer type*',
                _selectedVolunteerType,
                _volunteerTypes,
                (value) => setState(() => _selectedVolunteerType = value!),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 30, right: 16, top: 20, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Skills',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 24),
                      onPressed: _addSkill,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _skills.isEmpty
                    ? const Text(
                        'No skills added yet. Tap the + button to add skills.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills
                            .map((skill) => _buildSkillChip(skill))
                            .toList(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 30, right: 16, top: 24, bottom: 12),
                child: const Text(
                  'Education',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ..._buildEducationList(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                child: TextButton.icon(
                  onPressed: _addEducation,
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFF5CB89E),
                    size: 20,
                  ),
                  label: const Text(
                    'Add new education',
                    style: TextStyle(
                      color: Color(0xFF5CB89E),
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CB89E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEducationList() {
    List<Widget> educationWidgets = [];

    for (int i = 0; i < _education.length; i++) {
      final education = _education[i];
      educationWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    education['school'] ?? 'Unknown School',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (_education.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeEducation(i),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return educationWidgets;
  }

  Widget _buildFormField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              hintText: label.contains('First')
                  ? 'Enter first name'
                  : label.contains('Last')
                      ? 'Enter last name'
                      : label.contains('Email')
                          ? 'Enter email address'
                          : label.contains('Bio')
                              ? 'Enter your bio'
                              : label.contains('Location')
                                  ? 'Enter your location'
                                  : '',
            ),
            style: const TextStyle(fontSize: 16),
            validator: label.contains('*')
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Chip(
      label: Text(
        skill,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      backgroundColor: const Color(0xFF5CB89E),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      deleteIcon: const Icon(
        Icons.close,
        size: 16,
        color: Colors.white,
      ),
      onDeleted: () => _removeSkill(skill),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _schoolController.dispose();
    super.dispose();
  }
}
