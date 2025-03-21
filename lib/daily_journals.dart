import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class DailyJournalsPage extends StatefulWidget {
  final Widget drawer;
  const DailyJournalsPage({Key? key, required this.drawer}) : super(key: key);

  @override
  _DailyJournalsPageState createState() => _DailyJournalsPageState();
}

class _DailyJournalsPageState extends State<DailyJournalsPage> {
  int _currentQuestionIndex = 0;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  void _fetchUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
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
        "👨‍👩‍👧‍👦 With family": 1,
        "👫 With friends": 2,
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
        "🎨 🎮 Yes!": 1,
        "😕 No, I didn’t feel like it": 0
      },
      'field': "hobbies_selfcare"
    },
    {
      'question': "What affected your mood today?",
      'options': {
        "🤷 Nothing in particular": 0,
        "👔 Work stress": 1,
        "💔 Relationship issues": 2,
        "🏥 Health concerns": 3,
      },
      'field': "emotional_triggers"
    }
  ];

  /// Saves each response **immediately** to Firestore
  Future<void> _saveAnswer(String field, int value) async {
    if (_userEmail == null) return;

    DateTime today = DateTime.now();
    String formattedDate = "${today.year}-${today.month}-${today.day}";

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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                "📅 Select a Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
        backgroundColor: Colors.purpleAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendar,
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
                      backgroundColor: Colors.purpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(option, style: const TextStyle(fontSize: 16)),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
