import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'customer.dart';

class AnalysisPage extends StatefulWidget {
  final Widget drawer;
  const AnalysisPage({Key? key, required this.drawer}) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String? _userEmail;
  List<Map<String, dynamic>> _journalEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _fetchJournalEntries();
  }

  void _fetchUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  Future<void> _fetchJournalEntries() async {
    if (_userEmail == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('journals')
          .where('user_email', isEqualTo: _userEmail)
          .orderBy('date', descending: true)
          .limit(10) // Fetch only the last 10 entries
          .get();

      setState(() {
        _journalEntries = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'date': data['date'].toDate(),
            'mood': data['mood'],
            'social_interaction': data['social_interaction'],
            'work_productivity': data['work_productivity'],
            'hobbies_selfcare': data['hobbies_selfcare'],
            'emotional_triggers': data['emotional_triggers'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching journal entries: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch journal entries. Please try again.")),
      );
    }
  }

  // Calculate average mood score
  double _calculateAverageMood() {
    if (_journalEntries.isEmpty) return 0.0;

    double total = _journalEntries
        .map((entry) => (entry['mood'] ?? 0).toDouble()) // Convert mood to double
        .reduce((a, b) => a + b);

    return total / _journalEntries.length;
  }

  // Generate mood trend data for the chart
  List<FlSpot> _generateMoodTrendData() {
    return _journalEntries.asMap().entries.map((entry) {
      int index = entry.key;
      var data = entry.value;
      return FlSpot(
        index.toDouble(), // Convert index to double
        data['mood'].toDouble(), // Convert mood to double
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Journal Analysis"),
        backgroundColor: const Color.fromARGB(255, 222, 172, 231),
      ),
      drawer: widget.drawer, // Access the drawer via widget.drawer
      body: _journalEntries.isEmpty
          ? const Center(child: Text("No journal entries found."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📊 Mood Analysis",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Average Mood: ${_calculateAverageMood().toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateMoodTrendData(),
                            isCurved: true,
                            color: Colors.purple, // ✅ Correct parameter
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "📅 Recent Entries",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._journalEntries.take(5).map((entry) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text("Date: ${entry['date'].toString().split(' ')[0]}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mood: ${entry['mood']}"),
                            Text("Social Interaction: ${entry['social_interaction']}"),
                            Text("Work Productivity: ${entry['work_productivity']}"),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}