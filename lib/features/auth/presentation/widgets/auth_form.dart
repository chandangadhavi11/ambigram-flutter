import 'package:flutter/material.dart';

// An example widget if you want a separate form widget for login or signup.
class AuthForm extends StatefulWidget {
  final String buttonText;
  final void Function(String email, String password) onSubmit;

  const AuthForm({
    super.key,
    required this.buttonText,
    required this.onSubmit,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: () => widget.onSubmit(
            emailController.text.trim(),
            passwordController.text.trim(),
          ),
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}
