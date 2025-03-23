import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'customer.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

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
  double _calculateSadNumbPercentage() {
  if (_journalEntries.isEmpty) return 0.0;

  int sadNumbCount = _journalEntries
      .where((entry) => entry['mood'] == 2 || entry['mood'] == 3) // Numb or Sad
      .length;

  return (sadNumbCount / _journalEntries.length) * 100;
}
 Future<int> _predictDepressionRisk() async {
  if (_journalEntries.isEmpty) return 0;

  List<double> input = [
    (_journalEntries.last['mood'] ?? 0) / 3.0,  
    (_journalEntries.last['social_interaction'] ?? 0).toDouble(),
    (_journalEntries.last['work_productivity'] ?? 0).toDouble(),
    (_journalEntries.last['hobbies_selfcare'] ?? 0).toDouble(),
    (_journalEntries.last['emotional_triggers'] ?? 0).toDouble(),
    _calculateSadNumbPercentage() / 100.0,
  ];

  DepressionRiskPredictor predictor = DepressionRiskPredictor();
  await predictor.loadModel();

  // Standardize input before prediction
  List<double> standardizedInput = predictor.standardizeInput(input);
  var inputBuffer = Float32List.fromList(standardizedInput);

  int riskLevel = predictor.predict(inputBuffer);
  predictor.dispose();

  return riskLevel;
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
  String _getSuggestedAction(int riskLevel) {
  switch (riskLevel) {
    case 0:
      return "Keep up healthy habits; maintain social interactions.";
    case 1:
      return "Suggest engaging in hobbies/self-care; check in with close friends.";
    case 2:
      return "AI prompts for journaling reflection; soft nudge to reach out for help.";
    case 3:
      return "Recommend professional therapy; emergency support (if extreme cases).";
    default:
      return "No action suggested.";
  }
}

  // Calculate average mood score
double _calculateAverageMood() {
  if (_journalEntries.isEmpty) return 0.0;

  double total = _journalEntries
      .map<double>((entry) => (entry['mood'] ?? 0).toDouble()) // Explicitly cast
      .toList() // Ensure it's a list
      .reduce((double a,double b) => a + b); // Now reduce works correctly


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
    drawer: widget.drawer,
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
                          color: Colors.purple,
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
                const SizedBox(height: 24),
                FutureBuilder<int>(
                  future: _predictDepressionRisk(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      int riskLevel = snapshot.data ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Depression Risk Level: $riskLevel",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Suggested Action: ${_getSuggestedAction(riskLevel)}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
  );
}

}


class DepressionRiskPredictor {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/depression_model.tflite');
  }
   List<double> standardizeInput(List<double> inputValues) {
    List<double> means = [1.76585776 ,0.84334455 ,1.10908217 ,0.39572321 ,0.87121576 ,0.6230441 ];  // Replace with actual values
    List<double> stds =  [1.01825344, 0.82384873, 0.86740826, 0.48900547 ,1.02702217, 0.26236678];  // Replace with actual values

    List<double> scaledInput = [];
    for (int i = 0; i < inputValues.length; i++) {
      scaledInput.add((inputValues[i] - means[i]) / stds[i]);
    }
    return scaledInput;
  }

  int predict(Float32List input) {
    // Ensure output shape matches TensorFlow Lite output (batch_size=1, num_classes=4)
    
    var output = Float32List(4).reshape([1, 4]);
    print("Expected input shape: ${_interpreter.getInputTensor(0).shape}");
    print("Provided input: $input");

    _interpreter.run(input, output);

    // Find the index with the highest probability
    int riskLevel = output[0].indexWhere((element) => element == output[0].reduce((double a,double b) => a > b ? a : b));

    return riskLevel;
  }

  void dispose() {
    _interpreter.close();
  }
}
