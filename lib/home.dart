import 'package:flutter/material.dart';

//import 'package:getserved/admin.dart';

// Assuming you have StudentPage and ContracterPage widgets
import 'customer.dart'; // Import your StudentPage widget

class HomePage extends StatefulWidget {
  final String userRole; // 'student' or 'Contracter'

  const HomePage({super.key, required this.userRole});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnRole();
  }

  void _navigateBasedOnRole() {
    if (widget.userRole == 'Customer') {
      // Navigate to StudentPage
      Future.microtask(() => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Customer())));
    }
    //  else if (widget.userRole == 'Contracter') {
    //   // Navigate to ContracterPage
    //   Future.microtask(() => Navigator.pushReplacement(
    //       context, MaterialPageRoute(builder: (context) => const Contracter())));
    // }
    //  else if (widget.userRole == 'provider') {
    //   // Navigate to ContracterPage
    //   Future.microtask(() => Navigator.pushReplacement(
    //       context, MaterialPageRoute(builder: (context) => const Provider())));
    // }
    // else if (widget.userRole == 'Admin') {
    //   // Navigate to ContracterPage
    //   Future.microtask(() => Navigator.pushReplacement(
    //       context, MaterialPageRoute(builder: (context) => const Admin())));
    // }
  }

  @override
  Widget build(BuildContext context) {
    // Corrected method signature
    // You can return a temporary placeholder widget while routing happens.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Homepage"),
      ),
      body: const Center(
        child: CircularProgressIndicator(), // Loading indicator while routing
      ),
    );
  }
}
