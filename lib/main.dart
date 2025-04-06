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
  // 2. Optional: set local location
  tz.setLocalLocation(tz.getLocation('America/Detroit'));
  // or simply tz.setLocalLocation(tz.local);

  // 3. Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  // (Optional) Request iOS permissions
  if (Platform.isIOS) {
    await notificationService.requestIOSPermissions();
  }
  // (Optional) Request Android 13+ notifications permission
  // This will prompt the user on Android 13+ only
  await notificationService.requestAndroidPermissions();

  // Schedule for 3:00 PM (15:00 in 24-hour)
  await notificationService.scheduleDailyNotification(
    id: 1,
    hour: 15,
    minute: 0,
    title: 'Afternoon Reminder',
    body: 'Your 3 PM scheduled notification!',
  );

  // Schedule for 7:00 PM (19:00 in 24-hour)
  await notificationService.scheduleDailyNotification(
    id: 2,
    hour: 19,
    minute: 0,
    title: 'Evening Reminder',
    body: 'Your 7 PM scheduled notification!',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Industry-Level Flutter App',
      theme: AppTheme.lightTheme,
      routerDelegate: appRouter.routerDelegate,
      routeInformationParser: appRouter.routeInformationParser,
      routeInformationProvider: appRouter.routeInformationProvider,
      debugShowCheckedModeBanner: false,
    );
  }
}
