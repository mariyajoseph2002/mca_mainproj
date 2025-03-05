import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';
import 'customer.dart';

class MedicalRecordsScreen extends StatefulWidget {
  @override
  _MedicalRecordsScreenState createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final Customer customerWidget = Customer();
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

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not logged in!")));
      return;
    }

    // Extract specific details using OCR
 Map<String, dynamic> extractedData = await _ocrService.extractMedicalDetails(await _ocrService.extractText(image));
String base64Image = await _ocrService.convertImageToBase64(image);

// Save extracted data to Firestore
await _ocrService.saveExtractedData(extractedData, base64Image);

    setState(() {
      _selectedImage = image;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Medical record saved successfully!")));
  }

Future<List<Map<String, dynamic>>> fetchMedicalRecords() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  String userEmail = user.email ?? "unknown_user";
  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('medical_records')
      .doc(userEmail)
      .get();

  if (userDoc.exists && userDoc.data() != null) {
    var data = userDoc.data() as Map<String, dynamic>;

    // ✅ Ensure 'medical_data' exists and is a List
    if (data.containsKey('medical_data') && data['medical_data'] is List) {
      return List<Map<String, dynamic>>.from(data['medical_data']);
    }
  }

  return []; // ✅ Always return an empty list instead of null
}

 



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medical Records"), backgroundColor: const Color.fromARGB(255, 243, 173, 103)),
      drawer: customerWidget.buildDrawer(context),
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchMedicalRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No medical records found."));
                }

                List<Map<String, dynamic>> records = snapshot.data!;
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> record = records[index];
                    Uint8List imageBytes = base64Decode(record['imageBase64']);

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ExpansionTile(
                        leading: Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover),
                        title: Text("Doctor: ${record['doctor_name']}"),
                        subtitle: Text("Diagnosis: ${record['diagnosis']}"),
                        children: [
                          ListTile(
                            title: Text("📌 Doctor Details"),
                            subtitle: Text("Name: ${record['doctor_name']}\nContact: ${record['doctor_contact']}"),
                          ),
                          ListTile(
                            title: Text("💊 Medications"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: (record['medications'] as List)
                                  .map<Widget>((med) => Text("${med['name']} - ${med['dosage']}"))
                                  .toList(),
                            ),
                          ),
                          ListTile(
                            title: Text("📝 Instructions"),
                            subtitle: Text(record['instructions']),
                          ),
                          ListTile(
                            title: Text("📝 Follow up date"),
                            subtitle: Text(record['follow_up_date']),
                          ),
                          ListTile(
                            title: Text("🗓 Timestamp"),
                            subtitle: Text(record['timestamp'].toDate().toString()),
                          ),
                        ],
                      ),
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
