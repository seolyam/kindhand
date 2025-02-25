import 'package:flutter/material.dart';
import 'package:kindhand/services/api_service.dart';
import 'package:kindhand/utils/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return; // Ensure the widget is still mounted
      if (response['success']) {
        Navigator.of(context)
            .pushReplacementNamed('/account', arguments: response['user_id']);
      } else {
        context.showErrorSnackBar(message: response['message']);
      }
    } catch (error) {
      if (!mounted) return;
      context.showErrorSnackBar(message: 'An unexpected error occurred');
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: Text(_isLoading ? 'Loading' : 'Sign In'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/register'),
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
