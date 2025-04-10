import 'package:flutter/material.dart';
import 'core/navigation/router.dart';
import 'shared/themes/app_theme.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:flutter_application_1/features/notifications/notifications.dart';

void main() async {
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
    title: 'Afternoon Reminder',
    body: 'Your 3 PM scheduled notification!',
  );

  // • 7:00 PM
  await notificationService.scheduleDailyNotification(
    id: 2,
    hour: 19, // 7 PM in 24-hour format
    minute: 0,
    title: 'Evening Reminder',
    body: 'Your 7 PM scheduled notification!',
  );

  // 7. Run your app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Industry-Level Flutter App',
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
