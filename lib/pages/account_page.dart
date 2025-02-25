import 'package:flutter/material.dart';
import 'package:kindhand/services/api_service.dart';
import 'package:kindhand/utils/constants.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();
  var _loading = true;
  late String _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userId = ModalRoute.of(context)!.settings.arguments as String;
    _getProfile();
  }

  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await ApiService.getProfile(_userId);
      if (data['success']) {
        _usernameController.text = data['username'] ?? '';
        _websiteController.text = data['website'] ?? '';
      } else {
        context.showErrorSnackBar(message: data['message']);
      }
    } catch (error) {
      context.showErrorSnackBar(message: 'An unexpected error occurred');
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });
    try {
      final response = await ApiService.updateProfile(
        _userId,
        _usernameController.text,
        _websiteController.text,
      );
      if (response['success']) {
        context.showSnackBar(message: 'Profile updated successfully');
      } else {
        context.showErrorSnackBar(message: response['message']);
      }
    } catch (error) {
      context.showErrorSnackBar(message: 'An unexpected error occurred');
    }
    setState(() {
      _loading = false;
    });
  }

  void _signOut() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'User Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _updateProfile,
            child: Text(_loading ? 'Saving...' : 'Update'),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _signOut, child: const Text('Sign Out')),
        ],
      ),
    );
  }
}
