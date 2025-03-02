import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
              color: Color.fromARGB(255, 243, 173, 103),
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
        backgroundColor: const Color.fromARGB(255, 243, 173, 103),
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
