import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final String name;
  final String bio;
  final String greetingMessage;

  const ProfileWidget({
    super.key,
    required this.name,
    required this.bio,
    required this.greetingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greetingMessage,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Name: \$name',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Bio: \$bio',
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
