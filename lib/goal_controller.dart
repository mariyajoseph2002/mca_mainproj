import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoalController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userEmail;

  GoalController() {
    getUserEmail();
  }

  Future<void> getUserEmail() async {
    final user = _auth.currentUser;
    if (user != null) {
      userEmail = user.email;
    }
  }

  // Fetch goals of the current user from the 'goals' collection
  Stream<QuerySnapshot> fetchGoals() {
    if (userEmail == null) {
      return Stream.empty();
    }
    return _firestore
        .collection('goals')
        .where('userEmail', isEqualTo: userEmail) // Fetch only the logged-in user's goals
        .snapshots();
  }

  // Add a new goal to the 'goals' collection
  Future<void> addGoal(String title, String description, DateTime dueDate) async {
    if (userEmail == null) return;
    await _firestore.collection('goals').add({
      'title': title,
      'description': description,
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': dueDate,
      'userEmail': userEmail, // Store user's email for filtering
    });
  }

  // Update goal progress
  Future<void> updateGoalProgress(String goalId, int progress) async {
    await _firestore.collection('goals').doc(goalId).update({'progress': progress});
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) async {
    await _firestore.collection('goals').doc(goalId).delete();
  }

  // AI Suggested Goal Feature
Future<String?> fetchAiSuggestedGoal() async {
  if (userEmail == null) return "User not logged in!";
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  if (apiKey.isEmpty) return "API Key is missing!";

  final response = await http.post(
    Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$apiKey"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": "Suggest a personal development goal for someone looking to improve their lifestyle."}
          ]
        }
      ]
    }),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] ?? "No suggestion available";
  } else {
    print("❌ API Error: ${response.body}");
    return "AI failed to generate a goal!";
  }
}


  // Save AI Suggested Goal
  Future<void> saveAiSuggestedGoal(String suggestedGoal) async {
    if (userEmail == null) return;
    await addGoal(suggestedGoal, "AI Suggested Goal", DateTime.now().add(Duration(days: 30)));
  }
}
