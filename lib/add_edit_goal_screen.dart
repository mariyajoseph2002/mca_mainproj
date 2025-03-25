import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditGoalScreen extends StatefulWidget {
  final String? goalId; // Null if adding a new goal
  final Map<String, dynamic>? goalData;

  AddEditGoalScreen({this.goalId, this.goalData});

  @override
  _AddEditGoalScreenState createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDueDate;

  @override
  void initState() {
    super.initState();
    if (widget.goalData != null) {
      titleController.text = widget.goalData!['title'] ?? '';
      descriptionController.text = widget.goalData!['description'] ?? '';
      selectedDueDate = (widget.goalData!['dueDate'] as Timestamp?)?.toDate();
    }
  }

  Future<void> saveGoal() async {
    // Get the current logged-in user's email
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: No user logged in")),
      );
      return;
    }
    String userEmail = user.email ?? "";

    final goalData = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'progress': widget.goalData?['progress'] ?? 0, // Keep progress
      'createdAt': widget.goalData?['createdAt'] ?? FieldValue.serverTimestamp(), // Only set if new
      'dueDate': selectedDueDate != null ? Timestamp.fromDate(selectedDueDate!) : null,
      'userEmail': userEmail, // Associate goal with user
    };

    final goalRef = FirebaseFirestore.instance.collection('goals').doc(widget.goalId);

    if (widget.goalId == null) {
      // New goal - create a new document with an auto-generated ID
      await FirebaseFirestore.instance.collection('goals').add(goalData);
    } else {
      // Update existing goal
      await goalRef.update(goalData);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalId == null ? "Add Goal" : "Edit Goal"),
       backgroundColor:Color.fromARGB(255, 61, 93, 74),
        foregroundColor: const Color.fromARGB(255, 241, 250, 245),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Goal Title"),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Goal Description"),
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text(selectedDueDate == null
                  ? "Select Due Date"
                  : "Due Date: ${selectedDueDate!.toLocal()}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDueDate = pickedDate;
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 61, 93, 74),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              onPressed: saveGoal,
              child: Text("Save Goal"),
            ),
          ],
        ),
      ),
    );
  }
}