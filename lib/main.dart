import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'main_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

Future<void> requestNotificationPermission() async {
  NotificationSettings settings = await _firebaseMessaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Notification permission granted.");
  } else {
    print("Notification permission denied.");
  }
}


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> addRecommendations() async {
  final CollectionReference recommendations =
      FirebaseFirestore.instance.collection('recommendations');

  final docSnapshot = await recommendations.doc("Anger").get();
  if (docSnapshot.exists) {
    print("✅ Recommendations already exist. Skipping Firestore write.");
    return;
  }

  Map<String, Map<String, String>> emotionsData = {
    "Anger": { "affirmation": "I choose peace over anger.", "self_care_tip": "Take deep breaths and count to 10.", "journaling_prompt": "What triggered my anger today?", "suggested_goal": "Practice mindfulness daily." },
    "Fear": { "affirmation": "I am stronger than my fears.", "self_care_tip": "Write down your fears and rationalize them.", "journaling_prompt": "What is my biggest fear, and why?", "suggested_goal": "Try a new experience outside my comfort zone." },
    "Guilt": { "affirmation": "I forgive myself and grow from my mistakes.", "self_care_tip": "Write a letter of forgiveness to yourself.", "journaling_prompt": "What can I learn from this guilt?", "suggested_goal": "Practice self-compassion exercises." },
    "Hope": { "affirmation": "Every day is a new opportunity.", "self_care_tip": "Visualize a positive future.", "journaling_prompt": "What gives me hope in difficult times?", "suggested_goal": "List three things I look forward to this week." },
    "Joy": { "affirmation": "Happiness flows through me.", "self_care_tip": "Express gratitude for today’s joys.", "journaling_prompt": "What made me smile today?", "suggested_goal": "Keep a gratitude journal." },
    "Loneliness": { "affirmation": "I am never truly alone; I am enough.", "self_care_tip": "Reach out to a friend or loved one.", "journaling_prompt": "What makes me feel connected?", "suggested_goal": "Join a social or hobby group." },
    "Love": { "affirmation": "I am worthy of love and kindness.", "self_care_tip": "Do something kind for yourself today.", "journaling_prompt": "Who or what do I love most?", "suggested_goal": "Express appreciation to someone important to me." },
    "Neutral": { "affirmation": "I embrace balance and contentment.", "self_care_tip": "Reflect on your emotions and accept them.", "journaling_prompt": "What is something neutral in my life that I appreciate?", "suggested_goal": "Explore a new hobby or skill." },
    "Sadness": { "affirmation": "It's okay to feel sad. I am healing.", "self_care_tip": "Go for a walk in nature.", "journaling_prompt": "What is making me feel this way?", "suggested_goal": "Try a creative activity (art, music, writing)." },
    "Surprise": { "affirmation": "I welcome the unexpected with an open mind.", "self_care_tip": "Embrace spontaneity and try something new.", "journaling_prompt": "What unexpected event happened recently?", "suggested_goal": "Do one spontaneous act today." },
  };

  emotionsData.forEach((emotion, data) {
    recommendations.doc(emotion).set({
      "emotion": emotion,
      "affirmation": data["affirmation"],
      "self_care_tip": data["self_care_tip"],
      "journaling_prompt": data["journaling_prompt"],
      "suggested_goal": data["suggested_goal"],
    });
  });

  print("✅ Recommendations added to Firestore!");
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();
  await Firebase.initializeApp();
  addRecommendations();
  requestNotificationPermission();
  initializeNotifications();
  await NotificationService.initialize();
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
