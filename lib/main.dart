/* import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'main_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'timezone_helper.dart' ;

//import 'package:flutter_timezone/flutter_timezone.dart';



/* void initializeTimeZone() {
  tz.initializeTimeZones(); // ✅ Initialize all time zones
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // 🔹 Set to your local timezone
  print("✅ Time zone set to: ${tz.local}");
}
 */

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


    Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}
 
Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}


/* Future<void> initializeNotifications() async {
  // ✅ Android Initialization
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ Request permission only for iOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
} */
Future<void> requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
  }
}
/* void requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationSettings settings = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()!.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ Notification permission granted!");
  } else {
    print("❌ Notification permission denied!");
  }
} */


/* 
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  flutterLocalNotificationsPlugin.initialize(initSettings);
}
 */
Future<void> addRecommendations() async {
  final CollectionReference recommendations =
      FirebaseFirestore.instance.collection('recommendations');

  final docSnapshot = await recommendations.doc("Anger").get();
  if (docSnapshot.exists) {
    print("✅ Recommendations already exist. Skipping Firestore write.");
    return;
  }
  Map<String, Map<String, String>> emotionsData = {
    "Anger": {
      "affirmation": "I choose peace over anger.",
      "self_care_tip": "Take deep breaths and count to 10.",
      "journaling_prompt": "What triggered my anger today?",
      "suggested_goal": "Practice mindfulness daily.",
      "daily_challenge": "Write down three things you are grateful for today."
    },
    "Fear": {
      "affirmation": "I am stronger than my fears.",
      "self_care_tip": "Write down your fears and rationalize them.",
      "journaling_prompt": "What is my biggest fear, and why?",
      "suggested_goal": "Try a new experience outside my comfort zone.",
      "daily_challenge": "Do one thing that scares you today."
    },
    "Sadness": {
      "affirmation": "It's okay to feel sad. I am healing.",
      "self_care_tip": "Go for a walk in nature.",
      "journaling_prompt": "What is making me feel this way?",
      "suggested_goal": "Try a creative activity (art, music, writing).",
      "daily_challenge": "Listen to your favorite uplifting song."
    },
    "Guilt": {
      "affirmation": "I forgive myself and learn from my mistakes.",
      "self_care_tip": "Write a letter of self-forgiveness.",
      "journaling_prompt": "What can I do to make peace with my guilt?",
      "suggested_goal": "Practice self-compassion daily.",
      "daily_challenge": "Do one kind act for yourself today."
    },
    "Hope": {
      "affirmation": "There is always light at the end of the tunnel.",
      "self_care_tip": "Visualize a positive future.",
      "journaling_prompt": "What am I hopeful for?",
      "suggested_goal": "Set a small, achievable goal today.",
      "daily_challenge": "Write down one thing you're looking forward to."
    },
    "Joy": {
      "affirmation": "I embrace happiness and share it with others.",
      "self_care_tip": "Do something that makes you laugh.",
      "journaling_prompt": "What made me happy today?",
      "suggested_goal": "Engage in an activity that brings joy.",
      "daily_challenge": "Send a cheerful message to a friend."
    },
    "Loneliness": {
      "affirmation": "I am loved and connected to the world.",
      "self_care_tip": "Reach out to a friend or family member.",
      "journaling_prompt": "What can I do to feel more connected?",
      "suggested_goal": "Join a social group or community.",
      "daily_challenge": "Call or text someone you care about."
    },
    "Love": {
      "affirmation": "I am surrounded by love and kindness.",
      "self_care_tip": "Express gratitude to a loved one.",
      "journaling_prompt": "How do I express love in my life?",
      "suggested_goal": "Practice acts of kindness daily.",
      "daily_challenge": "Give someone a heartfelt compliment."
    },
    "Neutral": {
      "affirmation": "I acknowledge and accept my emotions as they are.",
      "self_care_tip": "Take a moment to reflect on your day.",
      "journaling_prompt": "What emotions have I experienced today?",
      "suggested_goal": "Practice mindfulness for a few minutes.",
      "daily_challenge": "Do a quick 5-minute meditation."
    },
    "Surprise": {
      "affirmation": "I welcome new experiences with an open mind.",
      "self_care_tip": "Embrace spontaneity today.",
      "journaling_prompt": "What unexpected event happened today?",
      "suggested_goal": "Be open to new experiences.",
      "daily_challenge": "Try something new and exciting today!"
    }
  };

  emotionsData.forEach((emotion, data) {
    recommendations.doc(emotion).set({
      "emotion": emotion,
      "affirmation": data["affirmation"],
      "self_care_tip": data["self_care_tip"],
      "journaling_prompt": data["journaling_prompt"],
      "suggested_goal": data["suggested_goal"],
      "daily_challenge": data["daily_challenge"],
    });
  });

  print("✅ Recommendations added to Firestore!");
}


/* Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();
  await Firebase.initializeApp();
  initializeTimeZone();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  await NotificationService.initialize();
  requestNotificationPermission();
  await requestExactAlarmPermission();
  addRecommendations();
  
  //initializeNotifications();
  runApp(const MyApp());
} */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    await Firebase.initializeApp();
    initializeTimeZone();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    await NotificationService.initialize();
    requestNotificationPermission();
    await requestExactAlarmPermission();
    addRecommendations();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('🔥 Error initializing app: $e');
    print('📜 Stack Trace: $stackTrace');
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[900],
      ),
      home: const MainPage(),
    );
  }
}
 */


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'main_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'timezone_helper.dart';

void initializeTimeZone() {
  tz.initializeTimeZones(); // ✅ Initialize all time zones
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // 🔹 Set to your local timezone
  print("✅ Time zone set to: ${tz.local}");
}

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}


Future<void> initializeNotifications() async {
  // ✅ Android Initialization
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ Request permission only for iOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}
Future<void> requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
  }
}
/* void requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationSettings settings = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()!.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ Notification permission granted!");
  } else {
    print("❌ Notification permission denied!");
  }
} */


/* 
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  flutterLocalNotificationsPlugin.initialize(initSettings);
}
 */
Future<void> addRecommendations() async {
  final CollectionReference recommendations =
      FirebaseFirestore.instance.collection('recommendations');

  final docSnapshot = await recommendations.doc("Anger").get();
  if (docSnapshot.exists) {
    print("✅ Recommendations already exist. Skipping Firestore write.");
    return;
  }
  Map<String, Map<String, String>> emotionsData = {
    "Anger": {
      "affirmation": "I choose peace over anger.",
      "self_care_tip": "Take deep breaths and count to 10.",
      "journaling_prompt": "What triggered my anger today?",
      "suggested_goal": "Practice mindfulness daily.",
      "daily_challenge": "Write down three things you are grateful for today."
    },
    "Fear": {
      "affirmation": "I am stronger than my fears.",
      "self_care_tip": "Write down your fears and rationalize them.",
      "journaling_prompt": "What is my biggest fear, and why?",
      "suggested_goal": "Try a new experience outside my comfort zone.",
      "daily_challenge": "Do one thing that scares you today."
    },
    "Sadness": {
      "affirmation": "It's okay to feel sad. I am healing.",
      "self_care_tip": "Go for a walk in nature.",
      "journaling_prompt": "What is making me feel this way?",
      "suggested_goal": "Try a creative activity (art, music, writing).",
      "daily_challenge": "Listen to your favorite uplifting song."
    },
    "Guilt": {
      "affirmation": "I forgive myself and learn from my mistakes.",
      "self_care_tip": "Write a letter of self-forgiveness.",
      "journaling_prompt": "What can I do to make peace with my guilt?",
      "suggested_goal": "Practice self-compassion daily.",
      "daily_challenge": "Do one kind act for yourself today."
    },
    "Hope": {
      "affirmation": "There is always light at the end of the tunnel.",
      "self_care_tip": "Visualize a positive future.",
      "journaling_prompt": "What am I hopeful for?",
      "suggested_goal": "Set a small, achievable goal today.",
      "daily_challenge": "Write down one thing you're looking forward to."
    },
    "Joy": {
      "affirmation": "I embrace happiness and share it with others.",
      "self_care_tip": "Do something that makes you laugh.",
      "journaling_prompt": "What made me happy today?",
      "suggested_goal": "Engage in an activity that brings joy.",
      "daily_challenge": "Send a cheerful message to a friend."
    },
    "Loneliness": {
      "affirmation": "I am loved and connected to the world.",
      "self_care_tip": "Reach out to a friend or family member.",
      "journaling_prompt": "What can I do to feel more connected?",
      "suggested_goal": "Join a social group or community.",
      "daily_challenge": "Call or text someone you care about."
    },
    "Love": {
      "affirmation": "I am surrounded by love and kindness.",
      "self_care_tip": "Express gratitude to a loved one.",
      "journaling_prompt": "How do I express love in my life?",
      "suggested_goal": "Practice acts of kindness daily.",
      "daily_challenge": "Give someone a heartfelt compliment."
    },
    "Neutral": {
      "affirmation": "I acknowledge and accept my emotions as they are.",
      "self_care_tip": "Take a moment to reflect on your day.",
      "journaling_prompt": "What emotions have I experienced today?",
      "suggested_goal": "Practice mindfulness for a few minutes.",
      "daily_challenge": "Do a quick 5-minute meditation."
    },
    "Surprise": {
      "affirmation": "I welcome new experiences with an open mind.",
      "self_care_tip": "Embrace spontaneity today.",
      "journaling_prompt": "What unexpected event happened today?",
      "suggested_goal": "Be open to new experiences.",
      "daily_challenge": "Try something new and exciting today!"
    }
  };

  emotionsData.forEach((emotion, data) {
    recommendations.doc(emotion).set({
      "emotion": emotion,
      "affirmation": data["affirmation"],
      "self_care_tip": data["self_care_tip"],
      "journaling_prompt": data["journaling_prompt"],
      "suggested_goal": data["suggested_goal"],
      "daily_challenge": data["daily_challenge"],
    });
  });

  print("✅ Recommendations added to Firestore!");
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();
  await Firebase.initializeApp();
  initializeTimeZone();
  //initializeTimeZone();
  await NotificationService.initialize();
  requestNotificationPermission();
  await requestExactAlarmPermission();
  addRecommendations();
  
  
  //initializeNotifications();
  
 
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[900],
      ),
      home: const MainPage(),
    );
  }
}