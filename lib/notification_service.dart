import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';  // This includes TimeOfDay


class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🔹 Initialize Notification Plugin
  static Future<void> initialize() async {
    tz.initializeTimeZones(); // ✅ Initialize timezones first
     tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // ✅ Request permission for Android 13+
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  // 🔹 Schedule Notification (Fixed for v19.0.0)
  // Original method accepting DateTime
static Future<void> scheduleNotification(
    int id, String title, String body, DateTime scheduledTime) async {
  print("🔹 Scheduling Notification (Original Time): $scheduledTime");

  final tz.TZDateTime localTime = tz.TZDateTime.from(scheduledTime, tz.local);
  print("⏳ Converted to Local Time Zone: $localTime");

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'medication_channel',
    'Medication Reminders',
    channelDescription: 'Sends reminders for medication and doctor appointments.',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    localTime,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
  );

  print("✅ Notification Scheduled at: $localTime");
}

// New method accepting TimeOfDay, renamed to avoid duplication
static Future<void> scheduleNotificationFromTimeOfDay(
    int id, String title, String body, TimeOfDay selectedTime) async {
  final DateTime now = DateTime.now();

  // Convert the selected time to a DateTime object
  final DateTime scheduledTime = DateTime(
    now.year,
    now.month,
    now.day,
    selectedTime.hour,
    selectedTime.minute,
  );

  // If the scheduled time is before now, set it for the next day
  final scheduledDate = scheduledTime.isBefore(now)
      ? scheduledTime.add(Duration(days: 1))
      : scheduledTime;

  // Convert the scheduled time to TZDateTime (timezone aware)
  final tz.TZDateTime localTime = tz.TZDateTime.from(scheduledDate, tz.local);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'medication_channel',
    'Medication Reminders',
    channelDescription: 'Sends reminders for medication and doctor appointments.',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    localTime,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
  );

  print("✅ Notification Scheduled at: $localTime");
}

}
