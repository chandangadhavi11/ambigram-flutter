import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_application_1/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter_application_1/features/preview/presentation/screens/preview_screen.dart';

/// Data object passed through `state.extra` when navigating to /preview.
class PreviewRouteData {
  final String firstWord;
  final String secondWord;
  final int selectedChipIndex;
  final int selectedColorIndex;
  final List<NamedColor> colors;

  const PreviewRouteData({
    required this.firstWord,
    required this.secondWord,
    required this.selectedChipIndex,
    required this.selectedColorIndex,
    required this.colors,
  });
}

/// Main router for the app.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

    //  ───────────── Preview route ─────────────
    GoRoute(
      path: '/preview',
      builder: (context, state) {
        // Expect a PreviewRouteData in state.extra.
        final data = state.extra as PreviewRouteData?;
        if (data == null) {
          // If someone navigates manually without arguments,
          // fall back to safe demo values so the app doesn’t crash.
          return PreviewScreen(
            firstWord: 'HELLO',
            secondWord: 'WORLD',
            selectedChipIndex: 0,
            selectedColorIndex: 0,
            colors: ColorPalette.fallbackChoices(),
          );
        }
        return PreviewScreen(
          firstWord: data.firstWord,
          secondWord: data.secondWord,
          selectedChipIndex: data.selectedChipIndex,
          selectedColorIndex: data.selectedColorIndex,
          colors: data.colors,
        );
      },
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
