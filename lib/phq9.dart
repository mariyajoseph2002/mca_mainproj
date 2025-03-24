import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PHQ9Screen extends StatefulWidget {
  @override
  _PHQ9ScreenState createState() => _PHQ9ScreenState();
}

class _PHQ9ScreenState extends State<PHQ9Screen> {
  double phq9Score = 0.0;
  List<double> moodData = [3, 2, 1, 0, 1, 2, 3]; // Placeholder for mood trend

  @override
  void initState() {
    super.initState();
    predictPHQ9Score();
  }
  Future<void> predictPHQ9Score() async {
    try{
  Interpreter interpreter = await Interpreter.fromAsset('assets/phq9_model.tflite');
  List<List<double>> input = await fetchLast7DaysJournal();

  // Reshape input to [1, 7, 7] as required by the model
  var inputTensor = [input];
  var outputTensor = List.filled(1, 0.0); // Output tensor

  interpreter.run(inputTensor, outputTensor);
  setState(() {
  double phq9Score = outputTensor[0]; // Get the predicted score
  //return phq9Score;
  });
    } catch (e) {
      print("Error in prediction: $e");
    }
}
Future<List<List<double>>> fetchLast7DaysJournal() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }

  String userEmail = user.email!;
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('journals')
      .where('user_email', isEqualTo: userEmail)
      .orderBy('date', descending: true)
      .limit(7)
      .get();

  List<List<double>> journalEntries = [];
  for (var doc in querySnapshot.docs) {
    var data = doc.data() as Map<String, dynamic>;
    journalEntries.add([
      data["mood"].toDouble(),
      data["social_interaction"].toDouble(),
      data["work_productivity"].toDouble(),
      data["hobbies_selfcare"].toDouble(),
      data["emotional_triggers"].toDouble(),
      data["sleep_quality"].toDouble(),
      data["appetite"].toDouble(),
    ]);
  }

  // If fewer than 7 entries, duplicate last available entry
  //while (journalEntries.length < 7) {
    //journalEntries.add(journalEntries.last);
  //}

  return journalEntries;
}
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PHQ-9 Mental Health Insights")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            phq9ScoreCard(),
            SizedBox(height: 16),
            moodTrendChart(),
            SizedBox(height: 16),
            behavioralInsights(),
            SizedBox(height: 16),
            aiRecommendation(),
          ],
        ),
      ),
    );
  }
  Widget phq9ScoreCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      color: Colors.deepPurpleAccent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("🎯 PHQ-9 Score", style: TextStyle(fontSize: 18, color: Colors.white)),
            SizedBox(height: 8),
            Text("${phq9Score.toStringAsFixed(1)}", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(getPHQ9Severity(phq9Score), style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
  String getPHQ9Severity(double score) {
     print("Predicted PHQ-9 Score: $score");
    if (score < 5) return "No Risk";
    if (score < 10) return "Mild Depression";
    if (score < 15) return "Moderate Depression";
    if (score < 20) return "Moderately Severe Depression";
    return "Severe Depression";
  }

  Widget moodTrendChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("📈 Mood Trend (Last 7 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(moodData.length, (index) => FlSpot(index.toDouble(), moodData[index])),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget behavioralInsights() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("🔹 Behavioral Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("📌 Social Interaction: Mostly with Friends"),
            Text("📌 Work Productivity: Moderate Performance"),
            Text("📌 Sleep: Poor (Need to improve)"),
            Text("📌 Appetite: Ate less than usual"),
          ],
        ),
      ),
    );
  }
  Widget aiRecommendation() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      color: Colors.greenAccent,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("🔥 AI Recommendation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('"Try journaling & guided meditation today!"', 
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

