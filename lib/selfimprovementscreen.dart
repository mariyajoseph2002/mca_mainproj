import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer.dart';

class SelfImprovementScreen extends StatefulWidget {
  final Widget drawer;
  const SelfImprovementScreen({super.key, required this.drawer});

  @override
  _SelfImprovementScreenState createState() => _SelfImprovementScreenState();
}

class _SelfImprovementScreenState extends State<SelfImprovementScreen> {
  String? userEmail;
  String _challenge = "Loading challenge...";

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _initializeChallenges();
  }

  /// Fetches the current user's email
  void _fetchUserEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
      print("✅ Logged in as: $userEmail");
    } else {
      print("❌ No user logged in!");
    }
  }

  /// Initializes challenges if the collection doesn't exist
  Future<void> _initializeChallenges() async {
    DocumentReference allChallengesRef = FirebaseFirestore.instance
        .collection('self_care_challenges')
        .doc('all_challenges');

    DocumentSnapshot doc = await allChallengesRef.get();

    if (!doc.exists) {
      List<String> challenges = [
        "Drink 8 glasses of water today.",
        "Take a 10-minute walk outdoors.",
        "Write down 3 things you're grateful for.",
        "Try a 5-minute deep breathing exercise.",
        "Read 10 pages of a book.",
        "Spend 30 minutes without your phone.",
        "Try a new healthy meal today.",
        "Listen to relaxing music for 10 minutes.",
        "Stretch for 5 minutes after waking up.",
        "Compliment yourself in the mirror.",
        "Write a short journal entry about your day.",
        "Do a 10-minute guided meditation.",
        "Get 7+ hours of sleep tonight.",
        "Watch a funny video and laugh out loud.",
        "Text a friend and check on them.",
        "Do a random act of kindness for someone.",
        "Declutter one small space in your home.",
        "Try a new hobby or activity for 15 minutes.",
        "Avoid social media for 1 hour today.",
        "Take a warm shower or bath to relax."
      ];

      await allChallengesRef.set({"challenges": challenges});
      print("✅ Self-care challenges added to Firestore!");
    }

    _fetchDailyChallenge();
  }

  /// Fetches a random daily challenge from Firestore
  Future<void> _fetchDailyChallenge() async {
    DocumentSnapshot dailyChallengeDoc = await FirebaseFirestore.instance
        .collection('self_care_challenges')
        .doc('daily')
        .get();

    if (dailyChallengeDoc.exists && dailyChallengeDoc.data() != null) {
      setState(() {
        _challenge = dailyChallengeDoc['challenge'] ?? "No challenge found!";
      });
    } else {
      await _assignNewDailyChallenge();
    }
  }

  /// Assigns a new random daily challenge
  Future<void> _assignNewDailyChallenge() async {
    DocumentSnapshot allChallengesDoc = await FirebaseFirestore.instance
        .collection('self_care_challenges')
        .doc('all_challenges')
        .get();

    if (allChallengesDoc.exists) {
      List<dynamic> challenges = allChallengesDoc['challenges'];
      challenges.shuffle();
      String newChallenge = challenges.first;

      await FirebaseFirestore.instance
          .collection('self_care_challenges')
          .doc('daily')
          .set({"challenge": newChallenge});

      setState(() {
        _challenge = newChallenge;
      });

      print("🎯 New daily challenge assigned: $newChallenge");
    }
  }

  /// Updates XP and Streak when the user completes a challenge
Future<void> _completeChallenge() async {
  print("🚀 Completing challenge...");

  if (userEmail == null) {
    print("❌ User email is null. Cannot update XP & Streak.");
    return;
  }

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: userEmail)
      .limit(1)
      .get();

  if (querySnapshot.docs.isEmpty) {
    print("❌ No user document found for email: $userEmail");
    return;
  }

  DocumentReference userRef = querySnapshot.docs.first.reference;

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot userDoc = await transaction.get(userRef);

    if (!userDoc.exists) {
      print("❌ User document does not exist!");
      return;
    }

    // Safely retrieve XP and Streak, providing default values if missing
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?; 
    int currentXP = userData?['xp'] ?? 0; 
    int currentStreak = userData?['streak'] ?? 0; 

    transaction.update(userRef, {
      'xp': currentXP + 10,
      'streak': currentStreak + 1,
    });

    print("🏆 XP Updated to ${currentXP + 10}, Streak: ${currentStreak + 1}");
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("🎉 Challenge Completed! +10 XP, Streak +1"),
      backgroundColor: Colors.green,
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Self-Improvement Challenges"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
      ),
      drawer: widget.drawer,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Today's Challenge:",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _challenge,
                      style: TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _completeChallenge,
                  icon: Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    "✅ Mark as Completed",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
