import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final goalData = {
      'title': titleController.text,
      'description': descriptionController.text,
      'progress': widget.goalData?['progress'] ?? 0, // Keep progress
      'createdAt': widget.goalData?['createdAt'] ?? FieldValue.serverTimestamp(), // Set createdAt only if new
      'dueDate': selectedDueDate != null ? Timestamp.fromDate(selectedDueDate!) : null,
    };

    if (widget.goalId == null) {
      // New goal
      await FirebaseFirestore.instance.collection('goals').add(goalData);
    } else {
      // Update existing goal
      await FirebaseFirestore.instance.collection('goals').doc(widget.goalId).update(goalData);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.goalId == null ? "Add Goal" : "Edit Goal")),
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
              onPressed: saveGoal,
              child: Text("Save Goal"),
            ),
          ],
        ),
      ),
    );
  }
}
