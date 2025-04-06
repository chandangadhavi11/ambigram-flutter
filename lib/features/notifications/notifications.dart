import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // 'app_icon' should be a drawable resource in Android (see docs)

    // iOS/ macOS initialization
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    // Linux initialization (optional if you want to support Linux)
    final LinuxInitializationSettings initializationSettingsLinux =
        const LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        );

    // Combine platform settings
    final InitializationSettings initSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  // iOS permission prompt (optional if you set requestPermission flags to false)
  Future<void> requestIOSPermissions() async {
    if (!Platform.isIOS) return;
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    debugPrint('iOS Permissions granted: $granted');
  }

  // Android 13+ POST_NOTIFICATIONS permission request
  Future<void> requestAndroidPermissions() async {
    if (!Platform.isAndroid) return;
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool? granted =
        await androidImplementation?.areNotificationsEnabled();
    debugPrint('Android Notification Permission: $granted');
  }

  // Callback when user taps on a notification (foreground)
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // You could navigate the user to a specific screen with Navigator here
  }

  /// Schedules a *daily* notification at the given hour & minute.
  Future<void> scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Define Android-specific details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_notifications_channel_id', // channel ID
          'Daily Notifications', // channel name
          channelDescription: 'Channel for daily notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    // iOS details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    // Combine
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      // other platforms if needed
    );

    // Calculate next instance of the specified time
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is already passed for today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Schedule it to repeat daily
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      payload: payload,
    );
  }

  /// For example, if you want to cancel all notifications or a specific one
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
