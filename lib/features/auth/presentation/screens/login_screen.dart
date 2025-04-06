import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/custom_card.dart';
import '../../../../global/state/auth_notifier.dart';
import '../../../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorText;

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!Validators.isValidEmail(email)) {
      setState(() {
        errorText = 'Invalid email format';
      });
      return;
    }

    if (!Validators.isValidPassword(password)) {
      setState(() {
        errorText = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() => errorText = null);

    final authNotifier = context.read<AuthNotifier>();
    try {
      await authNotifier.login(email, password);
      context.go('/home');
    } catch (e) {
      setState(() {
        errorText = 'Login failed. Please check your credentials.';
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorText != null)
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // If you had a signup flow, you could navigate there.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign Up pressed (not implemented)'),
                    ),
                  );
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
