import 'package:flutter/material.dart';
import 'core/navigation/router.dart';
import 'shared/themes/app_theme.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:flutter_application_1/features/notifications/notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize timezone data
  tz.initializeTimeZones();

  // 2. (Optional) Set local location
  tz.setLocalLocation(tz.getLocation(tz.local.name));
  // or simply: tz.setLocalLocation(tz.local);

  // 3. Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  // 4. Request iOS permissions
  if (Platform.isIOS) {
    await notificationService.requestIOSPermissions();
  }

  // 5. Request Android 13+ notifications permission (no-op on older versions)
  await notificationService.requestAndroidPermissions();

  // 6. Schedule daily notifications:

  // • 3:00 PM
  await notificationService.scheduleDailyNotification(
    id: 1,
    hour: 15, // 3 PM in 24-hour format
    minute: 0,
    title: 'Hello, Creator!',
    body:
        'It’s a perfect time to spark a little creativity. Make a new ambigram to brighten your day!',
  );

  // • 7:00 PM
  await notificationService.scheduleDailyNotification(
    id: 2,
    hour: 19, // 7 PM in 24-hour format
    minute: 0,
    title: 'Hope You’re Doing Well!',
    body:
        'Unwind with a dash of inspiration. Hop in and design another beautiful ambigram this evening.',
  );

  // 7. Run your app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ambigram',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerDelegate: appRouter.routerDelegate,
      routeInformationParser: appRouter.routeInformationParser,
      routeInformationProvider: appRouter.routeInformationProvider,
      debugShowCheckedModeBanner: false,
    );
  }
}
