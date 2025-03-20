import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'weekly_completion_screen.dart';
import 'dart:convert';
import 'goal_recommendation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class GoalDetailScreen extends StatefulWidget {
  final String goalId;
  final Map<String, dynamic> goal;

  GoalDetailScreen({required this.goalId, required this.goal});

  @override
  _GoalDetailScreenState createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  double progress = 0.0;
  late DateTime createdAt;
  late DateTime dueDate;
  double dailyIncrement = 0.0;
  DateTime? lastUpdatedDate;
  String recommendationText = "Fetching recommendation...";
  List<String> goalActivities = [];
 

  @override
  void initState() {
    super.initState();
    fetchRecommendation();
    checkAndFetchGoalActivities();
    progress = (widget.goal['progress'] ?? 0).toDouble();
    createdAt = widget.goal['createdAt']?.toDate() ?? DateTime.now();
    dueDate = widget.goal['dueDate']?.toDate() ?? DateTime.now();
    lastUpdatedDate = widget.goal['lastUpdated']?.toDate();

    int totalDays = dueDate.difference(createdAt).inDays;
    if (totalDays > 0) {
      dailyIncrement = 100 / totalDays;
    }
  }
  

Future<void> fetchRecommendation() async {
  String recommendation = await GoalRecommendationService.getAdaptiveRecommendation(widget.goalId);
  setState(() {
    recommendationText = recommendation;
  });
}


  /// Check Firestore for existing goal activities, use Gemini if not found
  Future<void> checkAndFetchGoalActivities() async {
    String category = widget.goal['title'] ;
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('goal_activity').doc(category).get();
      print("Fetching activities for category: $category");
print("Firestore snapshot data: ${snapshot.data()}");

      if (snapshot.exists && snapshot['activities'] != null) {
        List<String> activities = List<String>.from(snapshot['activities']);
        setState(() {
          goalActivities = activities;
        });
      } else {
        // If no activities exist, fetch from Gemini API
        await fetchActivitiesFromGemini(category);
      }
    } catch (e) {
      print("Error fetching goal activities: $e");
    }
  }

  /// Fetch suggested activities from Gemini API
  Future<void> fetchActivitiesFromGemini(String category) async {
    try {
      String geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; 
      final response = await http.post(
  Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$geminiApiKey"),
  headers: {"Content-Type": "application/json"},
  body: jsonEncode({
    "contents": [
      {
        "parts": [
          {
            "text": "Suggest 3 specific activities that can help someone achieve the goal category: $category. Provide the activities in a numbered list."
          }
        ]
      }
    ]
  }),
);


      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        //String aiResponse = jsonResponse['candidates'][0]['content'];
        String aiResponse = jsonResponse['candidates'][0]['content']['parts'][0]['text']
    .replaceAll('*', '') // Remove asterisks
    .trim(); // Trim extra spaces



        // Extract activities from response
        List<String> generatedActivities = aiResponse.split("\n").where((line) => line.isNotEmpty).toList();

        // Store AI-generated activities in Firestore for future use
        await FirebaseFirestore.instance.collection('goal_activity').doc(category).set({
          'activities': generatedActivities,
          'source': 'gemini',
          'created_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          goalActivities = generatedActivities;
        });
      } else {
        print("Error fetching activities from Gemini: ${response.body}");
      }
    } catch (e) {
      print("Exception while calling Gemini API: $e");
    }
  }




  Future<void> markStepCompleted() async {
    DateTime today = DateTime.now();
    String todayFormatted = "${today.year}-${today.month}-${today.day}";

    // Prevent multiple updates on the same day
    if (lastUpdatedDate != null &&
        lastUpdatedDate!.year == today.year &&
        lastUpdatedDate!.month == today.month &&
        lastUpdatedDate!.day == today.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You've already marked progress for today!")),
      );
      return;
    }

    // Check if the due date has passed
    if (today.isAfter(dueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Goal due date has passed! Progress cannot be updated.")),
      );
      return;
    }

    setState(() {
      progress += dailyIncrement;
      if (progress > 100) progress = 100;
      lastUpdatedDate = today;
    });

    // Update goal progress in Firestore
    await FirebaseFirestore.instance.collection('goals').doc(widget.goalId).update({
      'progress': progress,
      'lastUpdated': Timestamp.fromDate(today),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Add progress entry to progresshistory
   await FirebaseFirestore.instance
      .collection('goals')
      .doc(widget.goalId)
      .collection('progress_history')
      .doc(todayFormatted) // Store by date
      .set({'date': today, 'progress': progress}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Step marked as completed for today!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal['title']),
        backgroundColor: Colors.purpleAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal['title'],
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.goal['description'],
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Created: ${createdAt.toLocal()}",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      "Due: ${dueDate.toLocal()}",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    if (lastUpdatedDate != null)
                      Text(
                        "Last Updated: ${lastUpdatedDate!.toLocal()}",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      SizedBox(height: 20),
if (goalActivities.isNotEmpty) 
  Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 4,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Suggested Activities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...goalActivities.map((activity) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child:Row(
  crossAxisAlignment: CrossAxisAlignment.start, // Aligns items at the top
  children: [
    Icon(Icons.check_circle, color: Colors.green, size: 20), // Fixed small size
    SizedBox(width: 8), // Adds spacing
    Expanded( // Ensures text wraps and doesn't overflow
      child: Text(
        activity, 
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    ),
  ],
),


         
          )),
        ],
      ),
    ),
  ), 



                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Animated Progress Indicator
            Center(
              child: CircularPercentIndicator(
                radius: 100.0,
                lineWidth: 12.0,
                percent: (progress / 100).clamp(0.0, 1.0),
                center: Text("${progress.toInt()}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                progressColor: Colors.purpleAccent,
                backgroundColor: Colors.grey[300]!,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ),
            ),
            SizedBox(height: 20),
            Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  elevation: 4,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Adaptive Recommendation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(recommendationText, style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    ),
  ),
),


            // Mark as Completed Button
            Center(
              child: ElevatedButton(
                onPressed: markStepCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  "Mark Step as Completed",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 20),

            // View Weekly Completion Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeeklyCompletionScreen(goalId: widget.goalId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  "View Weekly Completion",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}  




