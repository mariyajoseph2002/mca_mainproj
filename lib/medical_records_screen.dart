/* import 'package:flutter/material.dart';
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
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr_service.dart';
import 'dart:io';

class MedicalRecordsScreen extends StatefulWidget {
  @override
  _MedicalRecordsScreenState createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final OCRService _ocrService = OCRService();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _processImage(ImageSource source) async {
    setState(() => _isLoading = true);

    File? image = await _ocrService.pickImage(source);
    if (image == null) {
      setState(() => _isLoading = false);
      return;
    }

    String extractedText = await _ocrService.extractText(image);
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String imageUrl = await _ocrService.uploadImageToFirebase(image, userId);
    await _ocrService.saveExtractedData(userId, extractedText, imageUrl);

    setState(() {
      _selectedImage = image;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data saved successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medical Records")),
      body: Column(
        children: [
          SizedBox(height: 16),

          // 📌 Buttons for Image Upload
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.camera),
                label: Text("Camera"),
                onPressed: () => _processImage(ImageSource.camera),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.image),
                label: Text("Gallery"),
                onPressed: () => _processImage(ImageSource.gallery),
              ),
            ],
          ),

          SizedBox(height: 16),

          // 📌 Display Uploaded Records in a List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('medical_records')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No medical records found."));
                }

                var records = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    var record = records[index];

                    return ListTile(
                      leading: Image.network(record['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(record['text']),
                      subtitle: Text(record['timestamp'].toDate().toString()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
