import 'package:flutter/material.dart';
import 'customer.dart';

class DailyJournalsPage extends StatelessWidget {
  const DailyJournalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Customer customerWidget = Customer(); // Reuse the drawer logic

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Journals"),
        backgroundColor: Color.fromARGB(255, 238, 160, 233),
      ),
      drawer: customerWidget.buildDrawer(context),
      body: const Center(
        child: Text(
          "Daily Journals Page",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
