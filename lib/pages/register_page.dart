import 'package:flutter/material.dart';
import 'package:kindhand/services/api_service.dart';
import 'package:kindhand/utils/constants.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.register(
        _emailController.text,
        _passwordController.text,
      );
      if (response['success']) {
        context.showSnackBar(
            message: 'Registration successful. Please log in.');
        Navigator.of(context).pop();
      } else {
        context.showErrorSnackBar(message: response['message']);
      }
    } catch (error) {
      context.showErrorSnackBar(message: 'An unexpected error occurred');
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
            onPressed: _isLoading ? null : _register,
            child: Text(_isLoading ? 'Loading' : 'Register'),
          ),
        ],
      ),
    );
  }
}
