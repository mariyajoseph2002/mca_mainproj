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
   _assignNewDailyChallenge();
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
  

  /// Assigns a new random daily challenge
Future<void> _assignNewDailyChallenge() async {
  DocumentReference dailyChallengeRef = FirebaseFirestore.instance
      .collection('self_care_challenges')
      .doc('daily');

  DocumentSnapshot dailyDoc = await dailyChallengeRef.get();

  String todayDate = DateTime.now().toIso8601String().split('T')[0]; // "YYYY-MM-DD"

  if (dailyDoc.exists && dailyDoc.data() != null) {
    Map<String, dynamic>? data = dailyDoc.data() as Map<String, dynamic>?;
    String lastUpdated = data?['date'] ?? '';

    // If today's challenge is already set, do nothing
    if (lastUpdated == todayDate) {
      setState(() {
        _challenge = data?['challenge'] ?? "No challenge found!";
      });
      print("✅ Today's challenge is already assigned.");
      return;
    }
  }

  // Fetch all challenges
  DocumentSnapshot allChallengesDoc = await FirebaseFirestore.instance
      .collection('self_care_challenges')
      .doc('all_challenges')
      .get();

  if (allChallengesDoc.exists) {
    List<dynamic> challenges = allChallengesDoc['challenges'];
    challenges.shuffle();
    String newChallenge = challenges.first;

    await dailyChallengeRef.set({
      "challenge": newChallenge,
      "date": todayDate, // Store the assigned date
    });

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
        backgroundColor:Color.fromARGB(255, 61, 93, 74),
        foregroundColor: const Color.fromARGB(255, 241, 250, 245),
        elevation: 5,
      ),
      drawer: widget.drawer,
      body: Container(
        /* decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ), */
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
                    color: Color.fromARGB(255, 61, 93, 74),
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
                        color: Color.fromARGB(255, 61, 93, 74),
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
                    style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 149, 206, 172)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 61, 93, 74),
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
