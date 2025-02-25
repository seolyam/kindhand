import 'package:flutter/material.dart';

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
  String _selectedCountry = 'Philippines';
  String _selectedVolunteerType = 'Online';
  List<String> _skills = [];
  List<Map<String, String>> _education = [];

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.userData['firstName']);
    _lastNameController =
        TextEditingController(text: widget.userData['lastName']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _bioController = TextEditingController(text: widget.userData['bio']);
    _locationController =
        TextEditingController(text: widget.userData['location']);
    _selectedCountry = widget.userData['country'];
    _selectedVolunteerType = widget.userData['volunteerType'];
    _skills = List<String>.from(widget.userData['skills']);
    _education = List<Map<String, String>>.from(widget.userData['education']);
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
        final yearsController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Education'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: schoolController,
                decoration: const InputDecoration(
                  hintText: 'School name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: yearsController,
                decoration: const InputDecoration(
                  hintText: 'Years (e.g., 2020-2026)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (schoolController.text.isNotEmpty &&
                    yearsController.text.isNotEmpty) {
                  setState(() {
                    _education.add({
                      'school': schoolController.text,
                      'years': yearsController.text,
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
        'bio': _bioController.text,
        'location': _locationController.text,
        'country': _selectedCountry,
        'volunteerType': _selectedVolunteerType,
        'skills': _skills,
        'education': _education,
        'status':
            'Student at University of St. La Salle', // This could also be made editable
      };
      widget.onSave(updatedData);
      Navigator.pop(context, updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Edit User Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '* indicates required',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFormField(
                        'First name*',
                        _firstNameController,
                        required: true,
                      ),
                      const SizedBox(height: 24),
                      _buildFormField(
                        'Last name*',
                        _lastNameController,
                        required: true,
                      ),
                      const SizedBox(height: 24),
                      _buildFormField(
                        'Email address',
                        _emailController,
                      ),
                      const SizedBox(height: 24),
                      _buildFormField(
                        'Bio',
                        _bioController,
                      ),
                      const SizedBox(height: 24),
                      _buildFormField(
                        'Location',
                        _locationController,
                      ),
                      const SizedBox(height: 24),
                      _buildDropdownField(
                        'Country/Region*',
                        _selectedCountry,
                        ['Philippines', 'Other'],
                        (value) => setState(() => _selectedCountry = value!),
                      ),
                      const SizedBox(height: 24),
                      _buildDropdownField(
                        'Preferred volunteer type*',
                        _selectedVolunteerType,
                        ['Online', 'On-site', 'Hybrid'],
                        (value) =>
                            setState(() => _selectedVolunteerType = value!),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Skills',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addSkill,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills
                            .map((skill) => _buildSkillChip(skill))
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Education',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._education.map((edu) => ListTile(
                            title: Text(edu['school']!),
                            subtitle: Text(edu['years']!),
                            contentPadding: EdgeInsets.zero,
                          )),
                      TextButton.icon(
                        onPressed: _addEducation,
                        icon: const Icon(
                          Icons.add,
                          color: Color(0xFF75B798),
                        ),
                        label: const Text(
                          'Add new education',
                          style: TextStyle(
                            color: Color(0xFF75B798),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF75B798),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF75B798)),
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
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
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
