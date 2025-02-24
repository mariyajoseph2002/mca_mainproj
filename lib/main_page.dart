import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';
// import 'home.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<String?> getUserRole(String uid) async {
    try {
      // Assuming the user data is stored in a Firestore collection called 'users'
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Assuming userRole is a field in the user's document
      return userDoc['role'];
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = snapshot.data;
            return FutureBuilder<String?>(
              future: getUserRole(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  //return const Center(child: Text("Error loading user role"));
                  return const LoginPage();
                  
                }

                String userRole = snapshot.data!;
                return HomePage(
                    userRole: userRole); // Pass the role to HomePage
              },
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
