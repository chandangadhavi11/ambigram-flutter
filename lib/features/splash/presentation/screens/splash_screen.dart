import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../global/state/auth_notifier.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Simulate some startup logic (e.g., checking auth status)
    Future.delayed(const Duration(seconds: 1), () {
      final isLoggedIn = context.read<AuthNotifier>().isLoggedIn;
      if (isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 0, 0, 0))),
    );
  }
}
