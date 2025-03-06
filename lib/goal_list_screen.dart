import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'goal_detail_screen.dart';
import 'add_edit_goal_screen.dart';
import 'customer.dart'; // Import customer.dart for drawer navigation

class GoalListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Customer customerWidget = Customer(); // Reuse the drawer logic

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purpleAccent,
        elevation: 0,
      ),
      drawer: customerWidget.buildDrawer(context), // Add the drawer navigation
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('goals').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching goals', style: TextStyle(color: Colors.red)));
          }

          final goals = snapshot.data?.docs ?? [];
          if (goals.isEmpty) {
            return Center(
              child: Text(
                'No goals found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final doc = goals[index]; // Firestore document reference
              final goalId = doc.id; // Extract Firestore document ID
              final goal = doc.data() as Map<String, dynamic>; // Convert Firestore data

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    goal['title'] ?? 'No Title',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6),
                      Text(
                        goal['description'] ?? 'No Description',
                        style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 37, 36, 36)),
                      ),
                      if (goal['createdAt'] != null)
                        Text(
                          "Created: ${goal['createdAt'].toDate().toLocal()}",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      if (goal['dueDate'] != null)
                        Text(
                          "Due: ${goal['dueDate'].toDate().toLocal()}",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      SizedBox(height: 8),
                      LinearPercentIndicator(
  lineHeight: 8.0,
  percent: ((goal['progress'] ?? 0) / 100).clamp(0.0, 1.0), // Ensure valid percentage
  backgroundColor: Colors.grey[300],
  linearGradient: LinearGradient(
    colors: [Colors.purpleAccent, Colors.blueAccent], // Gradient effect
  ),
  animation: true,
  animationDuration: 800,
  barRadius: Radius.circular(10),
),

                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalDetailScreen(
                          goalId: goalId, // Firestore document ID
                          goal: goal, // Goal data
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditGoalScreen()),
          );
        },
        backgroundColor: Colors.purpleAccent,
        child: Icon(Icons.add, size: 30),
      ),
    );
  }
}
