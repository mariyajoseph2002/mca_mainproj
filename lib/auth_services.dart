import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveUserData(userCredential.user!); // Save user data to SharedPreferences
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.uid);
    await prefs.setString('email', user.email ?? '');
    await prefs.setString('name', user.displayName ?? '');

    // Fetch additional user data from Firestore
    var documentSnapshot = await _firestore.collection('users').doc(user.uid).get();
    if (documentSnapshot.exists) {
      await prefs.setString('name', documentSnapshot.get('name') ?? '');
      await prefs.setString('role', documentSnapshot.get('role') ?? '');
    }
  }

  // Get current user data from SharedPreferences
  Future<Map<String, String?>> getCurrentUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId'),
      'email': prefs.getString('email'),
      'name': prefs.getString('name'),
      'role': prefs.getString('role'),
    };
  }

  // Fetch user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc['role'];
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }

  // Clear session data on logout
  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data
    await _auth.signOut();
  }
}