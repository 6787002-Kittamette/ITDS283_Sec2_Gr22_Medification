import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initializes the notification plugin and requests permissions
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  // Displays an immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'instant_alert_channel',
          'Instant Alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  // Schedules a daily notification at a specific time
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required String scheduledTime,
  }) async {
    final parts = scheduledTime.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_pill_channel',
          'Daily Medication Reminder',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedules a reminder for missed medications
  static Future<void> scheduleMissedNotification({
    required int id,
    required String title,
    required String body,
    required String scheduledTime,
    bool skipToday = false,
  }) async {
    final parts = scheduledTime.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'missed_pill_channel',
          'Missed Medication Reminder',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id + 20000,
      title,
      body,
      _nextInstanceOfTime(hour, minute, skipToday: skipToday),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancels all scheduled notifications for a specific ID
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    await _notificationsPlugin.cancel(id + 20000);
  }

  // Calculates the next valid occurrence of a given time
  static tz.TZDateTime _nextInstanceOfTime(
    int hour,
    int minute, {
    bool skipToday = false,
  }) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now) || skipToday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
