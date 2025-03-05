import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBase64Service {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(String userId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    File imageFile = File(image.path);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64String = base64Encode(imageBytes);

    await _firestore.collection('users').doc(userId).set({
      'profileImage': base64String,
    }, SetOptions(merge: true));

    debugPrint('Image uploaded as Base64');
  }

  Future<String?> fetchBase64Image(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();

    if (doc.exists && doc['profileImage'] != null) {
      return doc['profileImage'];
    }
    return null;
  }
}
