import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MedicalRecordsScreen extends StatefulWidget {
  @override
  final Widget drawer;
  const MedicalRecordsScreen({super.key, required this.drawer});
  _MedicalRecordsScreenState createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final OCRService _ocrService = OCRService();
  bool _isLoading = false;
  DateTime? _selectedNextCheckupDate;

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
    

    Map<String, dynamic> extractedData = await _ocrService.extractMedicalRecord(await _ocrService.extractText(image));
    String base64Image = await _ocrService.convertImageToBase64(image);

    // 🔹 Determine if it's a checkup or medical record
    bool isCheckupRecord = extractedData.containsKey('checkup_type'); 

     await _ocrService.saveData(image, context);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(isCheckupRecord ? "Checkup record saved!" : "Medical record saved!")),
);
setState(() => _isLoading = false);

  

    
  }


  Future<List<Map<String, dynamic>>> fetchRecords({bool isCheckup = false}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    String userEmail = user.email ?? "unknown_user";
    /* DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('medical_records').doc(userEmail).get();

    if (userDoc.exists && userDoc.data() != null) {
      var data = userDoc.data() as Map<String, dynamic>;
      String key = isCheckup ? 'checkup_data' : 'medical_data';
      if (data.containsKey(key) && data[key] is List) {
        return List<Map<String, dynamic>>.from(data[key]);
      }
    }
    return []; */
     String collectionName = isCheckup ? 'checkup_records' : 'medical_records';

  QuerySnapshot recordsSnapshot = await FirebaseFirestore.instance
      .collection(collectionName)
      .where('email', isEqualTo: userEmail)
      .get();

  return recordsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<String> fetchMedicationDetails(String medicationName) async {
    String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    String apiUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$apiKey";

    DocumentSnapshot medDoc = await FirebaseFirestore.instance
        .collection('medication_info')
        .doc(medicationName.toLowerCase())
        .get();

    if (medDoc.exists && medDoc.data() != null) {
      return (medDoc.data() as Map<String, dynamic>)['description'];
    }

    await Future.delayed(Duration(seconds: 2));

    Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {"text": "In two sentences, what is $medicationName used for in medical treatment?"}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String details = jsonResponse["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "No details found";

        await FirebaseFirestore.instance.collection('medication_info').doc(medicationName.toLowerCase()).set({
          'description': details,
        });

        return details;
      } else {
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Error fetching details: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Medical & Checkup Records"),
        backgroundColor: Color.fromARGB(255, 61, 93, 74),
        foregroundColor: Color.fromARGB(255, 241, 250, 245),
        elevation: 5,
      ),
      drawer: widget.drawer,
      body: Column(
        children: [
          SizedBox(height: 16),

          // 📌 Buttons for Image Upload
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUploadButton("Camera", Icons.camera, () => _processImage(ImageSource.camera)),
                SizedBox(width: 16),
                _buildUploadButton("Gallery", Icons.image, () => _processImage(ImageSource.gallery)),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 📌 Tabs for Viewing Records
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: "Medical Records"),
                      Tab(text: "Checkup Records"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRecordsList(false), // Medical Records
                        _buildRecordsList(true), // Checkup Records
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(bool isCheckup) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchRecords(isCheckup: isCheckup),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(isCheckup ? "No checkup records found." : "No medical records found."));
        }

        List<Map<String, dynamic>> records = snapshot.data!;
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> record = records[index];
            Uint8List imageBytes = base64Decode(record['imageBase64']);

            return Card(
              margin: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              shadowColor: Colors.black54,
              elevation: 5,
              child: ExpansionTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover),
                ),

             title: Text(
                isCheckup ? "Test: ${record['test_name']}" : "Doctor: ${record['doctor_name']}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(isCheckup ? "Observed Value: ${record['observed_value']}" : "Diagnosis: ${record['diagnosis']}"),
              children: isCheckup
                  ? [
                      _buildListTile("Test Name", record['test_name']),
                      _buildListTile("Observed Value", record['observed_value']),
                      _buildListTile("Next Check-up Date", record['next_checkup_date']), // 📌 New Field
                    ]
                : [
                  _buildListTile("Doctor", record['doctor_name']),
                  _buildListTile("Contact", record['doctor_contact']),
                  _buildListTile("Diagnosis", record['diagnosis']),
                  _buildMedicationsList(record['medications']),
                  _buildListTile("Instructions", record['instructions']),
                   _buildListTile("Follow-up Date", record['followup_date']),
                  ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUploadButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 95, 180, 132), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildListTile(String title, String subtitle) {
    return ListTile(title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle));
  }
  // 📌 Styled Medication List
Widget _buildMedicationsList(List medications) {
  return ListTile(
    title: Text("💊 Medications", style: TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: medications.map<Widget>((med) {
        return FutureBuilder<String>(
          future: fetchMedicationDetails(med['name']),
          builder: (context, medSnapshot) {
            if (medSnapshot.connectionState == ConnectionState.waiting) {
              return Text("${med['name']} - ${med['dosage']} (Fetching details...)");
            }
            return Text("${med['name']} - ${med['dosage']}\n💡 Purpose: ${medSnapshot.data}");
          },
        );
      }).toList(),
    ),
  );
}

}
