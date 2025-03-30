// Add these imports at the beginning of medical.dart
import 'dart:io'; // For File class
import 'package:intl/intl.dart'; // For DateFormat
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final Widget drawer;
  const MedicalRecordsScreen({super.key, required this.drawer});

  @override
  _MedicalRecordsScreenState createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final OCRService _ocrService = OCRService();
  bool _isLoading = false;
  final Map<String, String> _medicationCache = {};

  Future<void> _processImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      File? image = await _ocrService.pickImage(source);
      if (image != null) await _ocrService.saveData(image, context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecords(bool isCheckup) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    print("Fetching records for ${user.uid}");

  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(isCheckup ? 'checkup_records' : 'medical_record')
        .where('email', isEqualTo: user.email)
        .get();
  print("Found ${snapshot.docs.length} records");
    snapshot.docs.forEach((doc) => print(doc.data()));
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
        'timestamp':  _parseTimestamp(data['timestamp']),
      };
    }).toList();
  } catch (e) {
    print("Fetch error: $e");
    return [];
  }
}
Timestamp _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp;
  }
  if (timestamp is DateTime) {
    return Timestamp.fromDate(timestamp);
  }
  // Return current timestamp as fallback
  return Timestamp.now();
}

  Future<String> _fetchMedicationDetails(String medName) async {
    if (_medicationCache.containsKey(medName)) return _medicationCache[medName]!;
    
    final doc = await FirebaseFirestore.instance
        .collection('medication_info')
        .doc(medName.toLowerCase())
        .get();

    if (doc.exists) return doc['description'] ?? "No information available";

    // API call implementation here...
    
    return "Information not available";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Records"),
        backgroundColor: Color(0xFF3D5D4A),
        foregroundColor: Colors.white,
      ),
      drawer: widget.drawer,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadButton(Icons.camera, "Camera", ImageSource.camera),
                _buildUploadButton(Icons.photo, "Gallery", ImageSource.gallery),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Color(0xFF3D5D4A),
                    tabs: [
                      Tab(text: "Medical Records"),
                      Tab(text: "Checkup Reports"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRecordsList(false),
                        _buildRecordsList(true),
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
    return RefreshIndicator(
    onRefresh: () async {
      setState(() {}); // Force rebuild
    },
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecords(isCheckup),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No ${isCheckup ? 'checkup' : 'medical'} records found"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final record = snapshot.data![index];
            final imageBytes = base64Decode(record['imageBase64']);

            return Card(
              margin: EdgeInsets.all(10),
              child: ExpansionTile(
                leading: Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(isCheckup 
                    ? record['test_name'] ?? 'Checkup Report'
                    : record['doctor_name'] ?? 'Medical Record'),
                subtitle: Text(isCheckup
                    ? "Date: ${record['sample_date'] ?? 'Unknown Date'}"
                    : "Diagnosis: ${record['diagnosis'] ?? 'Not specified'}"),
                children: isCheckup
                    ? _buildCheckupDetails(record)
                    : _buildMedicalDetails(record),
              ),
            );
          },
        );
      },
    )
    );
    
  }

  List<Widget> _buildCheckupDetails(Map<String, dynamic> record) {
    return [
        _buildDetailTile("Test Name", record['test_name']?.toString()),
    _buildDetailTile("Blood Glucose", record['blood_glucose']?.toString()),
    _buildDetailTile("Cholesterol", record['cholesterol']?.toString()),
    _buildDetailTile("Blood Pressure", record['blood_pressure']?.toString()),
        _buildDetailTile(
      "Test Date",
      record['timestamp'] != null 
          ? DateFormat('dd MMM yyyy').format(
              (record['timestamp'] as Timestamp).toDate())
          : 'Date not available'
    ),
      _buildDetailTile("Next Checkup", 
          record['next_checkup_date'] != null 
              ? DateFormat("dd MMM yyyy").format(
                  DateTime.parse(record['next_checkup_date']))
              : "Not scheduled"),
    ];
  }

  List<Widget> _buildMedicalDetails(Map<String, dynamic> record) {
    return [
      _buildDetailTile("Doctor", record['doctor_name']?.toString()),
    _buildDetailTile("Contact", record['contact']?.toString()),
    _buildDetailTile("Diagnosis", record['diagnosis']?.toString()),
    _buildDetailTile("Instruction", record['instructions']?.toString()),
      _buildDetailTile(
      "Date",
      record['timestamp'] != null 
          ? DateFormat('dd MMM yyyy').format(
              (record['timestamp'] as Timestamp).toDate())
          : 'Date not available'
    ),
      _buildDetailTile("Follow-up Date", record['follow_up_date']),
      _buildMedicationList(record['medications']),
    ];
  }

 Widget _buildMedicationList(List<dynamic> medications) {
  return ExpansionTile(
    title: Text("💊 Medications (${medications.length})"),
    children: (medications ?? []).map<Widget>((med) { // Add null check
      final name = med['name']?.toString() ?? 'Unknown Medication';
      final dosage = med['dosage']?.toString() ?? 'Not specified';
      final duration = med['duration']?.toString() ?? 'Not specified';
      
      return FutureBuilder<String>(
        future: _fetchMedicationDetails(name),
        builder: (context, snapshot) {
          return ListTile(
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dosage: $dosage"),
                Text("Duration: $duration"),
                if (snapshot.hasData) Text("Info: ${snapshot.data}"),
              ],
            ),
          );
        },
      );
    }).toList(),
  );
}

 Widget _buildDetailTile(String title, dynamic value) {
  return ListTile(
    title: Text(title),
    trailing: Text(
      (value?.toString() ?? 'N/A'), // Handle null values
      style: TextStyle(color: Colors.grey[600]),
    ),
  );
}
  Widget _buildUploadButton(IconData icon, String label, ImageSource source) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF5FB484),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: _isLoading ? null : () => _processImage(source),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}