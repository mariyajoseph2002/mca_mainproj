import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🔹 Initialize Notification Plugin
  static Future<void> initialize() async {
    tz.initializeTimeZones(); // ✅ Initialize timezones first

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  // 🔹 Schedule Notification
  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_channel', // Unique channel ID
      'Medication Reminders', // Channel name
      channelDescription: 'Sends reminders for medication and doctor appointments.', // ✅ Required for Android 13+
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // Unique ID for each notification
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local), // Convert time to local timezone
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ Required for accuracy
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ✅ Allows daily repeating reminders
    );
  }
}
