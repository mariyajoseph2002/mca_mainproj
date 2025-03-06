import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId; // Firestore document ID
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
    progress = (widget.goal['progress'] ?? 0).toDouble();
    createdAt = widget.goal['createdAt']?.toDate() ?? DateTime.now();
    dueDate = widget.goal['dueDate']?.toDate() ?? DateTime.now();
    lastUpdatedDate = widget.goal['lastUpdated']?.toDate(); // Track last update date

    int totalDays = dueDate.difference(createdAt).inDays;
    if (totalDays > 0) {
      dailyIncrement = 100 / totalDays; // Progress increase per day
    }
  }

  Future<void> markStepCompleted() async {
    DateTime today = DateTime.now();

    // Ensure user can only update progress once per day
    if (lastUpdatedDate != null &&
        lastUpdatedDate!.year == today.year &&
        lastUpdatedDate!.month == today.month &&
        lastUpdatedDate!.day == today.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You've already marked progress for today!")),
      );
      return;
    }

    if (today.isAfter(dueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Goal due date has passed! Progress cannot be updated.")),
      );
      return;
    }

    setState(() {
      progress += dailyIncrement;
      if (progress > 100) progress = 100; // Cap progress at 100%
      lastUpdatedDate = today; // Update last completed date
    });

    await FirebaseFirestore.instance.collection('goals').doc(widget.goalId).update({
      'progress': progress,
      'lastUpdated': Timestamp.fromDate(today), // Store last updated date
      'updated_at': FieldValue.serverTimestamp(),
    });

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
                    if (widget.goal['createdAt'] != null)
                      Text(
                        "Created: ${createdAt.toLocal()}",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    if (widget.goal['dueDate'] != null)
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
          ],
        ),
      ),
    );
  }
}
