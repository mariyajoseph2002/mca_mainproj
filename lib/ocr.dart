import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

DateTime? parseFollowUpDate(String dateStr) {
  try {
    return DateFormat("dd-MM-yyyy").parse(dateStr);
  } catch (e) {
    try {
      return DateFormat("yyyy-MM-dd").parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}

class OCRService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<String> extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  void dispose() => _textRecognizer.close();

  Future<String> convertImageToBase64(File image) async {
    List<int> imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);
  }

  bool isCheckupRecord(String text) {
    final checkupKeywords = [
      'cholesterol', 'glucose', 'blood pressure',
      'medical lab', 'test results', 'laboratory report'
    ];
    return checkupKeywords.any((keyword) => text.toLowerCase().contains(keyword));
  }

  Map<String, dynamic> extractCheckupDetails(String text) {
    Map<String, dynamic> checkupData = {};

    // Enhanced Field Extraction
    RegExp testNameRegex = RegExp(r"Test Name\s*[:\.]\s*(.+)", caseSensitive: false);
    RegExp observedValueRegex = RegExp(r"Observed Value\s*[:\.]\s*(.+)", caseSensitive: false);
  RegExp glucoseRegex = RegExp(
    r"Blood\s*Glucose\s*(?:\(.*\))?\s*[:]?[\s\S]*?(\d+)\s*mg/dL",
    caseSensitive: false
  );
   RegExp cholesterolRegex = RegExp(
    r"Total\s*Cholesterol\s*[:]?[\s\S]*?(\d+)\s*mg/dL",
    caseSensitive: false
  );
    RegExp bpRegex = RegExp(r"Blood Pressure\s*[:\.]?\s*(\d+/\d+)", caseSensitive: false);
    RegExp dateRegex =RegExp(r"(Sample Received On|Report Released On)\s+(\d{2}-[A-Za-z]{3}-\d{4})", caseSensitive: false);

    checkupData = {
      "test_name": testNameRegex.firstMatch(text)?.group(1)?.trim() ?? "General Checkup",
      "observed_value": observedValueRegex.firstMatch(text)?.group(1)?.trim() ?? "Not available",
      "blood_glucose": glucoseRegex.firstMatch(text)?.group(1) ?? "Not detected",
      "cholesterol": cholesterolRegex.firstMatch(text)?.group(1) ?? "Not detected",
      "blood_pressure": bpRegex.firstMatch(text)?.group(1) ?? "Not available",
      "sample_date": dateRegex.firstMatch(text)?.group(1) ?? DateFormat("dd-MM-yyyy").format(DateTime.now()),
    };
      // Extract with debug logging
  print("==== CHECKUP EXTRACTION DEBUG ====");
  _logAndExtract(text, glucoseRegex, "Blood Glucose", checkupData);
  _logAndExtract(text, cholesterolRegex, "Cholesterol", checkupData);
  print("==================================");
    return checkupData;
  }
  void _logAndExtract(String text, RegExp pattern, String label, Map<String, dynamic> data) {
  Match? match = pattern.firstMatch(text);
  if (match != null) {
    print("✅ $label MATCH: ${match.group(0)}");
    data[label.toLowerCase().replaceAll(' ', '_')] = match.group(1);
  } else {
    print("❌ $label NOT FOUND");
    print("Scanned Text Snippet:\n${text.substring(0, 500)}..."); // First 500 chars
  }
}

  /* Map<String, dynamic> extractMedicalRecord(String text) {
    print('\n\n==== RAW OCR TEXT START ====');
    print(text);
    print('==== RAW OCR TEXT END ====\n\n');
    Map<String, dynamic> medicalData = {
      "doctor_name": "",
      "contact": "",
      "diagnosis": "",
      "follow_up_date": "",
      "instructions": "",
      "medications": [],
    };
    RegExp adviceRegex = RegExp(
    r"(Advice|Instructions)\s*[:]?\s*(.+?)(?=\n\w+:|$)",
    caseSensitive: false,
    dotAll: true
  );
  if (adviceRegex.hasMatch(text)) {
    medicalData["instructions"] = adviceRegex.firstMatch(text)!.group(2)!.trim();
  }


    RegExp doctorRegex = RegExp(r"(Dr\..+?)(?=\n|$)");
    RegExp contactRegex = RegExp(r"Ph(one)?\s*[:\.]?\s*([+\d- ]+)");
    RegExp diagnosisRegex = RegExp(r"Diagnosis\s*[:\.]\s*(.+)");
    RegExp followUpRegex = RegExp(r"(Follow[-\s]?Up|Next[-\s]?Appointment)\s*[:\.]?\s*(\d{2}-\d{2}-\d{4})");
    //RegExp medicationRegex = RegExp(r"(TAB|CAP)\.\s+(.+?)\s+-\s+(.+?)\s+-\s+(.+)");
    final medRegex = RegExp(
    r'(TAB|CAP)\.\s+([^\n]+?)\s+-\s+([^\n]+?)\s+-\s+([^\n]+?)(?=\n|$)',
    caseSensitive: false,
    multiLine: true
  );


    medicalData["doctor_name"] = doctorRegex.firstMatch(text)?.group(1)?.trim() ?? "Unknown Doctor";
    medicalData["contact"] = contactRegex.firstMatch(text)?.group(2)?.trim() ?? "N/A";
    medicalData["diagnosis"] = diagnosisRegex.firstMatch(text)?.group(1)?.trim() ?? "Not specified";
    
    var followUpMatch = followUpRegex.firstMatch(text);
    if (followUpMatch != null) {
      medicalData["follow_up_date"] = followUpMatch.group(2) ?? "";
    }

    // Medication Extraction
    /* medicationRegex.allMatches(text).forEach((match) {
      medicalData["medications"].add({
        "type": match.group(1),
        "name": match.group(2)?.trim(),
        "dosage": match.group(3)?.trim(),
        "duration": match.group(4)?.trim(),
      });
    }); */
  text.split('\n').forEach((line) {
    final medMatch = medRegex.firstMatch(line);
    if (medMatch != null) {
      medicalData["medications"].add({
        'type': medMatch.group(1) ?? '',
        'name': medMatch.group(2)?.trim() ?? '',
        'dosage': medMatch.group(3)?.trim() ?? '',
        'duration': medMatch.group(4)?.trim() ?? '',
      });
    }
  });

    return medicalData;
  }
 */
Map<String, dynamic> extractMedicalRecord(String text) {
  // Keep the debug logging
  print('\n\n==== RAW OCR TEXT START ====');
  print(text);
  print('==== RAW OCR TEXT END ====\n\n');

  // Initialize all fields with empty values
  Map<String, dynamic> medicalData = {
    "doctor_name": "",
    "contact": "",
    "diagnosis": "",
    "follow_up_date": "",
    "instructions": "",
    "medications": [],
  };

  // Use your original working variables
  List<String> medicineNames = [];
  List<String> dosages = [];
  List<String> durations = [];
  
  // Enhanced regex patterns from your original working code
  RegExp dosageRegex = RegExp(
    r"(\d+\s*(Morning|Night|Afternoon|Evening|Times|Once|Twice|Day|Days))", 
    caseSensitive: false
  );
  
  RegExp durationRegex = RegExp(
    r"(\d+\s*(Days|Weeks|Months))", 
    caseSensitive: false
  );

  // Process each line as in original working code
  List<String> lines = text.split('\n');
  for (String rawLine in lines) {
    String line = rawLine.trim();

    // Doctor Name (original logic)
    if (line.toLowerCase().contains("dr.") && medicalData["doctor_name"]!.isEmpty) {
      medicalData["doctor_name"] = line;
    }

    // Contact Info (original logic)
    if (line.toLowerCase().contains("ph") || line.toLowerCase().contains("mob")) {
      medicalData["contact"] = line.replaceAll(RegExp(r"[^0-9+]"), "");
    }

    // Diagnosis (original logic)
    if (line.toLowerCase().contains("diagnosis:")) {
      medicalData["diagnosis"] = line.split(":").last.trim();
    }

    // Follow-up Date (improved version)
    RegExp followUpRegex = RegExp(
      r"Follow[\s-]*Up[\s:]*(\d{1,2}[-\/]\d{1,2}[-\/]\d{4})", 
      caseSensitive: false
    );
    if (medicalData["follow_up_date"]!.isEmpty) {
      var match = followUpRegex.firstMatch(line);
      if (match != null) {
        medicalData["follow_up_date"] = match.group(1) ?? "";
      }
    }

    // Instructions (original logic)
    if (line.toLowerCase().contains("advice") || line.toLowerCase().contains("instructions")) {
      medicalData["instructions"] = line.split(":").last.trim();
    }

    // Medication Extraction (original working logic)
    if (line.startsWith("TAB.") || line.startsWith("CAP.")) {
      medicineNames.add(line.replaceFirst(RegExp(r"(TAB\.|CAP\.)\s*"), "").trim());
    }
    else if (dosageRegex.hasMatch(line)) {
      dosages.add(line.trim());
    }
    else if (durationRegex.hasMatch(line)) {
      durations.add(line.trim());
    }
  }

  // Combine medications using original logic with null safety
  for (int i = 0; i < medicineNames.length; i++) {
    medicalData["medications"].add({
      "name": medicineNames[i],
      "dosage": i < dosages.length ? dosages[i] : "",
      "duration": i < durations.length ? durations[i] : "",
    });
  }

  // Add the type field for Firebase structure
  return medicalData;
}
  Future<void> saveData(File image, BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String extractedText = await extractText(image);
      String base64Image = await convertImageToBase64(image);
      bool isCheckup = isCheckupRecord(extractedText);

      Map<String, dynamic> data = isCheckup 
          ? extractCheckupDetails(extractedText)
          : extractMedicalRecord(extractedText);

      data.addAll({
        "type": isCheckup ? "checkup" : "medical",
         'timestamp': FieldValue.serverTimestamp(), 
        "email": user.email,
        "imageBase64": base64Image,
      
      });

      String collection = isCheckup ? "checkup_records" : "medical_record";
       DocumentReference docRef = await FirebaseFirestore.instance
          .collection(collection)
          .add(data);


      // Schedule notifications
      if (isCheckup) {

        DateTime? nextDate = await askUserForNextCheckupDate(context);
        if (nextDate != null) {
          await docRef.update({
            "next_checkup_date": nextDate.toIso8601String()
          });
          
          NotificationService.scheduleNotification(
            nextDate.hashCode,
            "Check-Up Reminder",
            "Your next check-up is on ${DateFormat("dd MMM yyyy").format(nextDate)}",
            nextDate,
          );
        }
      } else {
        setReminders(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${isCheckup ? 'Checkup' : 'Medical'} record saved successfully!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving record: ${e.toString()}"))
      );
    }
  }

  Future<DateTime?> askUserForNextCheckupDate(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
  }

  void setReminders(Map<String, dynamic> medicalData) {
    List<Map<String, dynamic>> meds = List.from(medicalData["medications"]);
    DateTime now = DateTime.now();
    
    for (var med in meds) {
      String name = med["name"] ?? "Unknown Medication";
      String dosage = med["dosage"] ?? "";
      String duration = med["duration"] ?? "7 Days";
      
      int days =  int.tryParse(RegExp(r'\d+').firstMatch(duration)?.group(0) ?? '7') ?? 7;
      
      for (int i = 0; i < days; i++) {
        NotificationService.scheduleNotification(
          name.hashCode + i,
          "Medication Reminder",
          "Time to take $name - $dosage",
          now.add(Duration(days: i, hours: 9)),
        );
      }
    }
  }
}