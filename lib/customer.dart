/* import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healpal/goal_list_screen.dart';
import 'login.dart';
import 'daily_journals.dart';
import 'emotion_finder.dart'; // Updated import
import 'medical_records_screen.dart';


class Customer extends StatelessWidget {
  const Customer({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  void navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 238, 160, 233),
            ),
            child: const Center(
              child: Text(
                "Navigation Menu",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text("Daily Journals"),
            onTap: () {
              navigateToPage(context, const DailyJournalsPage());
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text("Goal"),
            onTap: () {
              navigateToPage(context,  GoalListScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.mood),
            title: const Text("Emotion Finder"),
            onTap: () {
              navigateToPage(context, EmotionFinderScreen()); // Updated navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text("Medical Records"),
            onTap: () {
              navigateToPage(context, MedicalRecordsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              logout(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer"),
        backgroundColor: Color.fromARGB(255, 238, 160, 233),
      ),
      drawer: buildDrawer(context),
      body: const Center(
        child: Text(
          "Welcome, Customer!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healpal/goal_list_screen.dart';
import 'login.dart';
import 'daily_journals.dart';
import 'emotion_finder.dart';
import 'medical_records_screen.dart';
import 'selfimprovementscreen.dart';

class Customer extends StatefulWidget {
  const Customer({super.key});

  @override
  _CustomerState createState() => _CustomerState();
}

class _CustomerState extends State<Customer> {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  int xp = 0;
  int streak = 0;
  String userName = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  /// Fetches XP, Streak, and Name from Firestore
  Future<void> _fetchUserDetails() async {
    if (userId.isEmpty) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          xp = int.tryParse(userDoc['xp'].toString()) ?? 0; // Ensuring it's an integer
          streak = int.tryParse(userDoc['streak'].toString()) ?? 0; // Ensuring it's an integer
          userName = userDoc['name'] ?? "User";
        });
      } else {
        setState(() {
          xp = 0;
          streak = 0;
          userName = "User";
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  void navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Custom Drawer Widget
  Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 238, 160, 233),
          ),
          accountName: Text(
            userName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          accountEmail: Text(
            "XP: $xp | Streak: $streak🔥",
            style: const TextStyle(fontSize: 16),
          ),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : "?",
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          ),
        ),
        buildDrawerItem(Icons.book, "Daily Journals", (drawer) => DailyJournalsPage(drawer: drawer)),
        buildDrawerItem(Icons.trending_up, "Goal", (drawer) => GoalListScreen(drawer: drawer)),
        buildDrawerItem(Icons.mood, "Emotion Finder", (drawer) => EmotionFinderScreen(drawer: drawer)),
        buildDrawerItem(Icons.folder, "Medical Records", (drawer) => MedicalRecordsScreen(drawer: drawer)),
        buildDrawerItem(Icons.eco, "Self Improvement", (drawer) => SelfImprovementScreen(drawer: drawer)),

        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Logout", style: TextStyle(color: Colors.red)),
          onTap: () {
            logout(context);
          },
        ),
      ],
    ),
  );
}

Widget buildDrawerItem(IconData icon, String title, Widget Function(Widget) pageBuilder) {
  return ListTile(
    leading: Icon(icon, color: Colors.purple),
    title: Text(title, style: const TextStyle(fontSize: 16)),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => pageBuilder(buildDrawer(context))),
      );
    },
  );
}


  /// Animated XP Progress Indicator
  Widget _buildXPIndicator() {
    return Column(
      children: [
        const Text("XP Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: (xp % 100) / 100, // Assuming level up every 100 XP
                strokeWidth: 8,
                color: Colors.purple,
                backgroundColor: Colors.grey[300],
              ),
            ),
            Text("$xp XP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  /// XP & Streak Card
  Widget _buildUserStats() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const Text("🔥 Your Progress", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildXPIndicator(),
                Column(
                  children: [
                    const Text("Current Streak", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("$streak Days", style: const TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Dashboard"),
        backgroundColor: Color.fromARGB(255, 238, 160, 233),
      ),
      drawer: buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUserStats(), // XP & Streak Card
            const SizedBox(height: 20),
            const Text(
              "Welcome to HealPal!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Track your goals, emotions, and medical records easily.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
