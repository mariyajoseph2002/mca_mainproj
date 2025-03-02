import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class OCRService {
  final ImagePicker _picker = ImagePicker();

  // Pick Image from Camera or Gallery
  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // Perform Text Recognition (OCR)
  Future<String> extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    
    String extractedText = recognizedText.text; // Full text
    await textRecognizer.close();
    return extractedText;
  }

  // Upload Image to Firebase Storage
  Future<String> uploadImageToFirebase(File image, String userId) async {
    String fileName = "medical_${DateTime.now().millisecondsSinceEpoch}.jpg";
    Reference ref = FirebaseStorage.instance.ref().child("medical_records/$userId/$fileName");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // Store Extracted Data in Firestore
  Future<void> saveExtractedData(String userId, String extractedText, String imageUrl) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).collection('medical_records').add({
      'text': extractedText,
      'imageUrl': imageUrl,
      'timestamp': DateTime.now(),
    });
  }
}
