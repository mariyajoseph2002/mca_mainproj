


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'notification_service.dart';

class DailyJournalsPage extends StatefulWidget {
  final Widget drawer;
  const DailyJournalsPage({Key? key, required this.drawer}) : super(key: key);

  @override
  _DailyJournalsPageState createState() => _DailyJournalsPageState();
}

class _DailyJournalsPageState extends State<DailyJournalsPage> {
  int _currentQuestionIndex = 0;
  String? _userEmail;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _loadReminderTime();
     _initializeNotificationService();
  }

  void _fetchUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }
    Future<void> _initializeNotificationService() async {
    await NotificationService.initialize();
  }

  Future<void> _loadReminderTime() async {
    if (_userEmail == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('user_settings')
        .doc(_userEmail)
        .get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['reminder_time'] != null) {
        setState(() {
          _reminderTime = TimeOfDay(
            hour: data['reminder_time']['hour'],
            minute: data['reminder_time']['minute'],
          );
        });
      }
    }
  }

  Future<void> _saveReminderTime(TimeOfDay time) async {
    if (_userEmail == null) return;

    await FirebaseFirestore.instance
        .collection('user_settings')
        .doc(_userEmail)
        .set({
      'reminder_time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      }, SetOptions(merge: true));

    setState(() {
      _reminderTime = time;
    });

   await NotificationService.scheduleNotificationFromTimeOfDay(
      0, // Notification ID
      'Reminder', // Notification Title
      'How is your day going? Share with us! !', // Notification Body
      time, // User-selected time
    );
  
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      await _saveReminderTime(pickedTime);
    }
  }

  final List<Map<String, dynamic>> _questions = [
    {
      'question': "How did you feel today?",
      'options': {
        "😊 Content": 0,
        "😐 Normal": 1,
        "😶 Numb": 2,
        "😢 Sad": 3
      },
      'field': "mood"
    },
    {
      'question': "Did you spend time with loved ones today?",
      'options': {
        "No, I was alone": 0,
        "👨‍👩‍👧‍👦 With family": 2,
        "👫 With friends": 3,
        "Don't feel like meeting anyone ": 1,
      },
      'field': "social_interaction"
    },
    {
      'question': "How was your work/study day?",
      'options': {
        "✅ Productive and fulfilling": 0,
        "⚖️ Got some things done": 1,
        "🤯 Struggled to focus": 2,
      },
      'field': "work_productivity"
    },
    {
      'question': "Did you engage in any hobbies today?",
      'options': {
        "🎨 🎮 Yes!": 2,
        "😕 No, I didn’t feel like it": 0,
        "Didn't have time":1,
      },
      'field': "hobbies_selfcare"
    },
    {
      'question': "What affected your mood today?",
      'options': {
        "🤷 Nothing in particular": 0,
        "😕 Slight issues":1,
        "👔 Work stress": 2,
        "💔 Relationship issues": 2,
        "🏥 Health concerns": 2,
      },
      'field': "emotional_triggers"
    },
    {
    'question': "How was your sleep last night?",
    'options': {
        "😴 Good (≥ 6 hours, few/no interruptions)": 0,
        "😐 Fair (4-6 hours, some interruptions)": 1,
        "😩 Poor (< 4 hours, frequent interruptions)": 3,
    },
    'field': "sleep_quality"
    },
     {
      'question': "How has your appetite been today?",
      'options': {
        "😋 Normal": 0,
        "🍽️ Ate less/more than usual": 1,
        "❌ Had no appetite": 2,
      },
      'field': "appetite"
    }

  ];

  /// Saves each response **immediately** to Firestore
/*   Future<void> _saveAnswer(String field, int value) async {
    if (_userEmail == null) return;

    DateTime today = DateTime.now();
    String formattedDate = "${today.year}-${today.month}-${today.day}";
     DocumentSnapshot journalDoc = await FirebaseFirestore.instance
      .collection('journals')
      .doc("$_userEmail-$formattedDate")
      .get();

  if (journalDoc.exists) {
    // If a journal entry exists, show a message and return
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You have already completed today's journal.")),
    );
    return;
  }

    DocumentReference journalRef = FirebaseFirestore.instance
        .collection('journals')
        .doc("$_userEmail-$formattedDate");

    await journalRef.set(
      {
        'user_email': _userEmail,
        'date': today,
        field: value,
      },
      SetOptions(merge: true), // Merge ensures previous answers aren't lost
    );
  }

  void _selectAnswer(String answer) async {
    String field = _questions[_currentQuestionIndex]['field'];
    int value = _questions[_currentQuestionIndex]['options'][answer];

    await _saveAnswer(field, value);

    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _showCompletionMessage();
      }
    });
  }

  void _showCompletionMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("✅ Journal Completed"),
        content: const Text("Your responses have been saved successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentQuestionIndex = 0;
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
 */
Future<void> _saveAnswer(String field, int value) async {
  if (_userEmail == null) return;

  DateTime today = DateTime.now();
  String formattedDate = "${today.year}-${today.month}-${today.day}";

  try {
    // Check if a journal entry already exists for today
    DocumentSnapshot journalDoc = await FirebaseFirestore.instance
        .collection('journals')
        .doc("$_userEmail-$formattedDate")
        .get();

    if (journalDoc.exists) {
      // If a journal entry exists, show a message and return
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have already completed today's journal.")),
      );
      return; // Do nothing further if the journal exists
    }

    // If no journal entry exists, save the journal data for today
    DocumentReference journalRef = FirebaseFirestore.instance
        .collection('journals')
        .doc("$_userEmail-$formattedDate");

    await journalRef.set(
      {
        'user_email': _userEmail,
        'date': today,
        field: value,
      },
      SetOptions(merge: true), // Merge ensures previous answers aren't lost
    );

    // Show completion message after successful saving
    _showCompletionMessage();

  } catch (e) {
    // Handle errors (network issues, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to save journal. Please try again.")),
    );
  }
}

void _selectAnswer(String answer) async {
  String field = _questions[_currentQuestionIndex]['field'];
  int value = _questions[_currentQuestionIndex]['options'][answer];

  // Save the answer and proceed only if it is saved successfully
  await _saveAnswer(field, value);

  // If the journal has been saved, move to the next question or show completion message
  setState(() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
    } else {
      // If all questions are answered, show the completion message
      _showCompletionMessage();
    }
  });
}

void _showCompletionMessage() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("✅ Journal Completed"),
      content: const Text("Your responses have been saved successfully!"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _currentQuestionIndex = 0; // Reset to the first question for the next entry
            });
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}


 void _showCalendar() async {
  if (_userEmail == null) return;

  // Fetch completed journal dates
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('journals')
      .where('user_email', isEqualTo: _userEmail)
      .get();

  // Extract completed dates
  Set<DateTime> completedDates = snapshot.docs.map((doc) {
    Timestamp timestamp = doc['date'];
    DateTime date = timestamp.toDate();
    return DateTime(date.year, date.month, date.day); // Normalize date
  }).toSet();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, 
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Set max height to 80% of screen height
          ),
          child: Column(
             mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "📅 Select a Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
               const SizedBox(height: 16),
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: DateTime.now(),
                  calendarFormat: CalendarFormat.month,
                  eventLoader: (day) {
                    return completedDates.contains(day) ? ['✅'] : [];
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          bottom: 5,
                          child: Text("✅", style: TextStyle(fontSize: 16)),
                        );
                      }
                      return null;
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    Navigator.pop(context);
                    _fetchJournalForDate(selectedDay);
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}


  void _fetchJournalForDate(DateTime date) async {
    if (_userEmail == null) return;

    String formattedDate = "${date.year}-${date.month}-${date.day}";
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('journals')
        .doc("$_userEmail-$formattedDate")
        .get();

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No journal entry found for this date.")),
      );
      return;
    }

    var journalData = doc.data() as Map<String, dynamic>;
    _showJournalEntry(journalData);
  }

  void _showJournalEntry(Map<String, dynamic> journalData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("📖 Journal Entry"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _questions.map((q) {
            int value = journalData[q['field']] ?? 0;
            String selectedOption = q['options'].keys.firstWhere(
              (key) => q['options'][key] == value,
              orElse: () => "Unknown",
            );
            return ListTile(
              title: Text(q['question']),
              subtitle: Text(selectedOption),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Journals"),
        backgroundColor: const Color.fromARGB(255, 222, 172, 231),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendar,
          ),
          IconButton(
            icon: const Icon(Icons.alarm),
            onPressed: _showTimePicker,
          ),
        ],
      ),
      drawer: widget.drawer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                question['question'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...question['options'].keys.map((option) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ElevatedButton(
                    onPressed: () => _selectAnswer(option),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  const Color.fromARGB(255, 222, 172, 231),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(option, style: const TextStyle(fontSize: 16)),
                  ),
                );
              }).toList(),
              if (_reminderTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "⏰ Reminder set for ${_reminderTime!.format(context)}",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
