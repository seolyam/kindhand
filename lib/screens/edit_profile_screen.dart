import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // Import the login screen

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
  String _selectedCountry = 'Philippines';
  String _selectedVolunteerType = 'Online';
  List<String> _skills = [];
  List<Map<String, String>> _education = [];
  late TextEditingController _schoolController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.userData['firstName']);
    _lastNameController =
        TextEditingController(text: widget.userData['lastName']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _selectedCountry = widget.userData['country'] ?? 'Philippines';
    _selectedVolunteerType = widget.userData['volunteerType'] ?? 'Online';
    _skills = List<String>.from(widget.userData['skills'] ?? []);
    _education =
        List<Map<String, String>>.from(widget.userData['education'] ?? []);
    _schoolController = TextEditingController(
        text: _education.isNotEmpty
            ? _education[0]['school']
            : 'University of St. La Salle');
  }

  Future<void> _logout() async {
    try {
      // Clear shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login screen and clear navigation stack
      if (mounted) {
        // Use MaterialPageRoute instead of named route
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
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
                    _education.add({
                      'school': schoolController.text,
                    });
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'country': _selectedCountry,
        'volunteerType': _selectedVolunteerType,
        'skills': _skills,
        'education': _education,
      };
      widget.onSave(updatedData);
      Navigator.pop(context, updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildDropdownField(
                'Country/Region*',
                _selectedCountry,
                ['Philippines', 'United States', 'Canada', 'Other'],
                (value) => setState(() => _selectedCountry = value!),
              ),
              _buildDropdownField(
                'Preferred volunteer type*',
                _selectedVolunteerType,
                ['Online', 'On-site', 'Hybrid'],
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
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_skills.isEmpty) ...[
                      _buildSkillChip('UI/UX'),
                      _buildSkillChip('Videography'),
                      _buildSkillChip('Logo'),
                    ] else
                      ..._skills.map((skill) => _buildSkillChip(skill)),
                  ],
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
              _buildDropdownField(
                'School*',
                _schoolController.text,
                ['University of St. La Salle', 'Other'],
                (value) {
                  setState(() {
                    _schoolController.text = value!;
                    if (_education.isEmpty) {
                      _education.add({'school': value});
                    } else {
                      _education[0]['school'] = value;
                    }
                  });
                },
              ),
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

  Widget _buildFormField(
    String label,
    TextEditingController controller,
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
                      : 'Enter email address',
            ),
            style: const TextStyle(
              fontSize: 16,
            ),
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

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF5CB89E),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    super.dispose();
  }
}
