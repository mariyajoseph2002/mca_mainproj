import 'package:flutter/material.dart';
import 'customer.dart';
import 'notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

void logTimeZone() {
  print("🌍 Device Time Zone: ${tz.local}");
}


class DailyJournalsPage extends StatelessWidget {
  final Widget drawer;
  const DailyJournalsPage({Key? key, required this.drawer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Customer customerWidget = Customer(); // Reuse the drawer logic

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Journals"),
        backgroundColor: Color.fromARGB(255, 238, 160, 233),
      ),
      drawer: drawer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
             onPressed: () {
              logTimeZone();
  DateTime now = DateTime.now().add(Duration(minutes: 1)); // ⏳ 30 sec delay
  NotificationService.scheduleNotification(
    1,
    "Test Reminder",
    "This is a test notification",
    now,
  );
  print("🚀 Test notification scheduled!");
},

              child: Text("⏰ Test Scheduled Notification"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showInstantNotification();
              },
              child: Text("🔔 Test Immediate Notification"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔔 **Immediate Notification Test**
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Immediate test notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await NotificationService.flutterLocalNotificationsPlugin.show(
      100,  // Unique ID
      "🚀 Immediate Notification",
      "If you see this, notifications work!",
      details,
    );

    print("✅ Immediate notification sent!");
  }
}
