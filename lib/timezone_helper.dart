import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
//import 'package:healpal/timezone_helper.dart';
import 'package:flutter_timezone/flutter_timezone.dart'; // ✅ Correct import

Future<void> initializeTimeZone() async {
  tz.initializeTimeZones();
  
  try {
    //final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone(); // ✅ No more undefined error
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    print("🌍 Detected Time Zone: "); // Debugging
    print(await FlutterTimezone.getLocalTimezone());
    // ✅ Set the local time zone
  } catch (e) {
    print("❌ Error fetching time zone: $e");
  }
}
