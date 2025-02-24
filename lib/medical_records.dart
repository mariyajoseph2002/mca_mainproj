import 'package:flutter/material.dart';
import 'customer.dart';

class MedicalRecordsPage extends StatelessWidget {
  const MedicalRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Customer customerWidget = Customer(); // Reuse the drawer logic

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Records"),
        backgroundColor: const Color.fromARGB(255, 243, 173, 103),
      ),
      drawer: customerWidget.buildDrawer(context),
      body: const Center(
        child: Text(
          "Medical Records Page",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
