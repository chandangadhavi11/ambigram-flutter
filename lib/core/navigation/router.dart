import 'package:flutter_application_1/features/preview/presentation/screens/preview_screen.dart';
import 'package:go_router/go_router.dart';

// Import screens
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

// This router config sets up our main routes in the app.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/preview',
      builder:
          (context, state) => const PreviewScreen(
            firstWord: 'Hello',
            secondWord: 'World',
            selectedChipIndex: 0,
            selectedColorIndex: 0,
          ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
