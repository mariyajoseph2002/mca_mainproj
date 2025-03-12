/* import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'goal_controller.dart';
import 'goal_detail_screen.dart';
import 'add_edit_goal_screen.dart';
import 'customer.dart';

class GoalListScreen extends StatefulWidget {
  @override
  _GoalListScreenState createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  final GoalController _goalController = GoalController();
  String? suggestedGoal;
  bool isLoadingAiGoal = false;

  void fetchAiGoal() async {
    setState(() => isLoadingAiGoal = true);
    String? goal = await _goalController.fetchAiSuggestedGoal();
    setState(() {
      suggestedGoal = goal;
      isLoadingAiGoal = false;
    });
  }

  void saveAiGoal() async {
    if (suggestedGoal != null) {
      await _goalController.saveAiSuggestedGoal(suggestedGoal!);
      setState(() => suggestedGoal = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Suggested Goal Saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Customer customerWidget = Customer();

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purpleAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline),
            onPressed: fetchAiGoal,
          ),
        ],
      ),
      drawer: customerWidget.buildDrawer(context),
      body: Column(
        children: [
          if (suggestedGoal != null) _buildAiSuggestedGoalCard(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _goalController.fetchGoals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error fetching goals',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final goals = snapshot.data?.docs ?? [];
                if (goals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'No goals found. Tap the "+" button to add one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final doc = goals[index];
                    final goalId = doc.id;
                    final goal = doc.data() as Map<String, dynamic>?;

                    if (goal == null || !goal.containsKey('title') || !goal.containsKey('progress')) {
                      return SizedBox(); // Skip invalid goals
                    }

                    return _buildGoalCard(goal, goalId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddEditGoalScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, String goalId) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal['title'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (goal['description'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  goal['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: ((goal['progress'] ?? 0) / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300]!,
              progressColor: Colors.purpleAccent,
              barRadius: Radius.circular(5),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoalDetailScreen(goalId: goalId, goal: goal)),
                ),
                child: Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSuggestedGoalCard() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Suggested Goal:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                isLoadingAiGoal
                    ? Center(child: CircularProgressIndicator())
                    : Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          suggestedGoal ?? 'No suggestion available',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: fetchAiGoal,
                      child: Text('Regenerate', style: TextStyle(color: Colors.purpleAccent)),
                    ),
                    ElevatedButton(
                      onPressed: saveAiGoal,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                      child: Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 */
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'goal_controller.dart';
import 'goal_detail_screen.dart';
import 'add_edit_goal_screen.dart';
import 'customer.dart';
import 'confidence_builder_screen.dart'; // Import new screen

class GoalListScreen extends StatefulWidget {
  @override
  _GoalListScreenState createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  final GoalController _goalController = GoalController();
  String? suggestedGoal;
  bool isLoadingAiGoal = false;

  void fetchAiGoal() async {
    setState(() => isLoadingAiGoal = true);
    String? goal = await _goalController.fetchAiSuggestedGoal();
    
    setState(() {
      suggestedGoal = goal?.replaceAll('*', '').trim(); // Remove asterisks
      isLoadingAiGoal = false;
    });
  }

  void saveAiGoal() async {
    if (suggestedGoal != null) {
      await _goalController.saveAiSuggestedGoal(suggestedGoal!);
      setState(() => suggestedGoal = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Suggested Goal Saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Customer customerWidget = Customer();

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purpleAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline),
            onPressed: fetchAiGoal,
          ),
        ],
      ),
      drawer: customerWidget.buildDrawer(context),
      body: SingleChildScrollView(  // Fixes overflow issue
        child: Column(
          children: [
            if (suggestedGoal != null) _buildAiSuggestedGoalCard(),

            StreamBuilder<QuerySnapshot>(
              stream: _goalController.fetchGoals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error fetching goals',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final goals = snapshot.data?.docs ?? [];
                if (goals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No goals found. Tap the "+" button to add one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true, // Fix overflow issue
                  physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final doc = goals[index];
                    final goalId = doc.id;
                    final goal = doc.data() as Map<String, dynamic>?;

                    if (goal == null || !goal.containsKey('title') || !goal.containsKey('progress')) {
                      return SizedBox(); // Skip invalid goals
                    }

                    return _buildGoalCard(goal, goalId);
                  },
                );
              },
            ),

            /// 🔹 Button to Navigate to Confidence Builder Screen 🔹 ///
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConfidenceBuilderScreen()),
                  );
                },
                child: Text("Explore Confidence Builder", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddEditGoalScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAiSuggestedGoalCard() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Suggested Goal:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              isLoadingAiGoal
                  ? Center(child: CircularProgressIndicator())
                  : Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        suggestedGoal ?? 'No suggestion available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: fetchAiGoal,
                    child: Text('Regenerate', style: TextStyle(color: Colors.purpleAccent)),
                  ),
                  ElevatedButton(
                    onPressed: saveAiGoal,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, String goalId) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal['title'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (goal['description'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  goal['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: ((goal['progress'] ?? 0) / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300]!,
              progressColor: Colors.purpleAccent,
              barRadius: Radius.circular(5),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoalDetailScreen(goalId: goalId, goal: goal)),
                ),
                child: Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

