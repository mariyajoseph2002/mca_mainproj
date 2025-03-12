import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'weekly_completion_screen.dart';
import 'goal_recommendation_service.dart';

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

  @override
  void initState() {
    super.initState();
    fetchRecommendation();
    progress = (widget.goal['progress'] ?? 0).toDouble();
    createdAt = widget.goal['createdAt']?.toDate() ?? DateTime.now();
    dueDate = widget.goal['dueDate']?.toDate() ?? DateTime.now();
    lastUpdatedDate = widget.goal['lastUpdated']?.toDate();

    int totalDays = dueDate.difference(createdAt).inDays;
    if (totalDays > 0) {
      dailyIncrement = 100 / totalDays;
    }
  }
  String recommendationText = "Fetching recommendation...";

Future<void> fetchRecommendation() async {
  String recommendation = await GoalRecommendationService.getAdaptiveRecommendation(widget.goalId);
  setState(() {
    recommendationText = recommendation;
  });
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
