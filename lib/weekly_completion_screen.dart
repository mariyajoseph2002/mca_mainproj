import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyCompletionScreen extends StatefulWidget {
  final String goalId;

  WeeklyCompletionScreen({required this.goalId});

  @override
  _WeeklyCompletionScreenState createState() => _WeeklyCompletionScreenState();
}

class _WeeklyCompletionScreenState extends State<WeeklyCompletionScreen> {
  List<FlSpot> weeklyData = [];

  @override
  void initState() {
    super.initState();
    fetchWeeklyCompletion();
  }

  Future<void> fetchWeeklyCompletion() async {
    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1)); // Start of the week (Monday)
    DateTime weekEnd = weekStart.add(Duration(days: 6)); // End of the week (Sunday)

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('goals')
        .doc(widget.goalId)
        .collection('progress_history') // Store daily progress here
        .where('date', isGreaterThanOrEqualTo: weekStart)
        .where('date', isLessThanOrEqualTo: weekEnd)
        .orderBy('date')
        .get();

    List<FlSpot> data = [];
    int index = 0;

    for (var doc in snapshot.docs) {
      double progress = (doc['progress'] ?? 0).toDouble();
      data.add(FlSpot(index.toDouble(), progress));
      index++;
    }

    setState(() {
      weeklyData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Weekly Progress"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Weekly Completion Rate",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            weeklyData.isEmpty
                ? Center(child: Text("No progress data available for this week."))
                : Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 20),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weeklyData,
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 3,
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
}
