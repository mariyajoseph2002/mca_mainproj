/* void _showScheduledNotification(
      int id, String habit, String description, String timeString) {
    print("$timeString"); // Debugging log
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    final now = tz.TZDateTime.now(tz.local);
    print(now); // Debugging log
    timeString = timeString.replaceAll(RegExp(r'\s+'), ' ').trim();
    print("time:$timeString"); // Debugging log

    try {
      var splited = timeString.split(':');
      var split = splited[1].split(' ');
      splited[1] = split[0];
      splited.add(split[1]);

      print(splited); // Debugging log'

      int hour = splited[2] == "PM"
          ? (int.parse(splited[0]) % 12 + 12)
          : int.parse(splited[0]);
int minute = int.parse(splited[1]); // Debugging log

      // Extract hours and minutes in 24-hour format
      // int hour = dateTime.hour;
      // int minute = dateTime.minute;
      print("Parsed Time -> Hour: $hour, Minute: $minute");
      print("$hour : $minute"); // Debugging log
      NotiServices.scheduledNotification(
        id,
        habit,
        description,
        _nextInstanceOfTime(hour, minute),
      );
    } catch (e) {
      print("Error parsing time: $e"); // Debugging log
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    print("🔹 Current Local Time: $now"); // Debugging log

    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    print(
        "🔹 Scheduled Time Before Adjustment: $scheduledDate"); // Debugging log

    // If the scheduled time is in the past, schedule it for the next day
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("🔹 Final Scheduled Time: $scheduledDate"); // Debugging log
    return scheduledDate;
  } */