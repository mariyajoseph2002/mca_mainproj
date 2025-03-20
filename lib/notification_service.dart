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

    // ✅ Request permission for Android 13+
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  // 🔹 Schedule Notification (Fixed for v19.0.0)
  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    print("🔹 Scheduling Notification (Original Time): $scheduledTime");

    final tz.TZDateTime localTime = tz.TZDateTime.from(scheduledTime, tz.local);
    print("⏳ Converted to Local Time Zone: $localTime"); // ✅ Debugging log

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
      localTime, // ✅ Use converted local time
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ Required in v19
      matchDateTimeComponents: DateTimeComponents.time, // ✅ Allows daily repeating reminders
    );
    print("✅ Notification Scheduled at: $localTime");
  }
}
