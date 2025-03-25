import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfidenceBuilderScreen extends StatefulWidget {
  @override
  _ConfidenceBuilderScreenState createState() => _ConfidenceBuilderScreenState();
}

class _ConfidenceBuilderScreenState extends State<ConfidenceBuilderScreen> {
  final TextEditingController _struggleController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> challenges = [];
  int currentStep = 0;
  bool isLoading = false;

  Future<void> fetchAiChallenges(String struggle) async {
    setState(() => isLoading = true);

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print("❌ API Key missing!");
      return;
    }

    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "Suggest 4 step-by-step challenges to help someone overcome '$struggle' in personal growth."}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<String> aiChallenges = (data['candidates'][0]['content']['parts'][0]['text'] as String)
          .split("\n")
          .where((line) => line.trim().isNotEmpty)
          .toList();

      setState(() {
        challenges = aiChallenges;
        currentStep = 0;
        isLoading = false;
      });
    } else {
      print("❌ API Error: ${response.body}");
      setState(() => isLoading = false);
    }
  }

  void completeStep() {
    if (currentStep < challenges.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      _saveCompletedChallenge();
      _showEncouragementDialog();
    }
  }

  void _saveCompletedChallenge() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('confidence_goals').add({
      'userEmail': user.email,
      'struggle': _struggleController.text,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showEncouragementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Great job! 🎉"),
        content: Text("You've completed all the steps! Keep pushing yourself."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confidence Builder"),backgroundColor:Color.fromARGB(255, 61, 93, 74),
        foregroundColor:  const Color.fromARGB(255, 241, 250, 245),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What are you struggling with?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _struggleController,
              decoration: InputDecoration(
                hintText: "E.g., Speaking up in meetings",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 61, 93, 74),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              onPressed: () => fetchAiChallenges(_struggleController.text),
              child: Text("Get AI Challenges"),
            ),
            SizedBox(height: 20),
            if (isLoading) Center(child: CircularProgressIndicator()),
            if (challenges.isNotEmpty) _buildChallengeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Step-by-step Challenges:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: (currentStep + 1) / challenges.length,
          backgroundColor: Colors.grey[300]!,
          progressColor: const Color.fromARGB(255, 14, 7, 143),
          barRadius: Radius.circular(5),
        ),
        SizedBox(height: 10),
        Text(
          "✅ Step ${currentStep + 1}: ${challenges[currentStep]}",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: completeStep,
          child: Text(currentStep < challenges.length - 1 ? "Complete Step" : "Finish"),
        ),
      ],
    );
  }
}
