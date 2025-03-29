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
    // Try parsing with the expected format
    return DateFormat("dd-MM-yyyy").parse(dateStr);
  } catch (e) {
    print("❌ Error parsing follow-up date: $dateStr. Trying alternative format...");

    // Try parsing with another common format
    try {
      return DateFormat("yyyy-MM-dd").parse(dateStr);
    } catch (e) {
      print("❌ Failed alternative parsing for follow-up date: $dateStr");
      return null; // Return null if parsing fails
    }
  }
}class OCRService {
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
  void dispose() {
    _textRecognizer.close(); // ✅ Proper cleanup
  }

  Future<String> convertImageToBase64(File image) async {
    List<int> imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);
  }

  /// 📌 Identify if it's a Medical Record or a Check-Up Record
  bool isCheckupRecord(String text) {
   final checkupKeywords = ['cholesterol', 'glucose', 'blood pressure', 'medical lab', 'test results'];
  return checkupKeywords.any((keyword) => text.toLowerCase().contains(keyword));
  }

  /// 📌 Extract Check-Up Data (Cholesterol, Blood Glucose, etc.)
Map<String, dynamic> extractCheckupDetails(String text) {
  Map<String, dynamic> checkupData = {};

  // Extract Sample Received Date
  RegExp sampleDateRegex = RegExp(r"Sample Received On\s*:\s*([\d-]+ \d+:\d+ [AP]M)");
  if (sampleDateRegex.hasMatch(text)) {
    checkupData["sample_received"] = sampleDateRegex.firstMatch(text)!.group(1);
  }

  // Extract Blood Glucose
  RegExp glucoseRegex = RegExp(r"Blood Glucose \(Random\)\s+(\d+)\s*mg/dL");
  if (glucoseRegex.hasMatch(text)) {
    checkupData["blood_glucose"] = glucoseRegex.firstMatch(text)!.group(1);
  }

  // Extract Total Cholesterol
  RegExp cholesterolRegex = RegExp(r"Total Cholesterol\s+(\d+)\s*mg/dL");
  if (cholesterolRegex.hasMatch(text)) {
    checkupData["cholesterol"] = cholesterolRegex.firstMatch(text)!.group(1);
  }

  // Extract Blood Pressure (Format: 120/80 mmHg or 120/80)
  RegExp bpRegex = RegExp(r"Blood Pressure\s*[:\s]+(\d+/\d+)");
  if (bpRegex.hasMatch(text)) {
    checkupData["blood_pressure"] = bpRegex.firstMatch(text)!.group(1);
  }

  return checkupData;
}


  /// 📌 Extract Medical Record (Generic Text)
  Map<String, dynamic> extractMedicalRecord(String text) {
    String doctorName = "";
  String contact = "";
  String diagnosis = "";
  String followUpDate = "";
  String instructions = "";
  List<Map<String, String>> medications = [];

  List<String> lines = text.split("\n");

  List<String> medicineNames = [];
  List<String> dosages = [];
  List<String> durations = [];

  RegExp dosageRegex = RegExp(r"(\d+\s*(Morning|Night|Afternoon|Evening|Times|Once|Twice))", caseSensitive: false);
  RegExp durationRegex = RegExp(r"(\d+\s*Days)", caseSensitive: false);

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i].trim();

    // Extract Doctor Name
    if (line.toLowerCase().contains("dr.") && doctorName.isEmpty) {
      doctorName = line;
    }

    // Extract Contact Information
    if (line.toLowerCase().contains("ph") || line.toLowerCase().contains("mob")) {
      contact = line.replaceAll(RegExp(r"[^0-9+]"), "");
    }

    // Extract Diagnosis
    if (line.toLowerCase().contains("diagnosis:")) {
      diagnosis = line.split(":").last.trim();
    }

    // Extract Follow-up Date
   RegExp followUpRegex = RegExp(
  r"(Follow[-\s]?Up|Next[-\s]?Appointment|Scheduled on):?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{4})",
  caseSensitive: false,
);

    if (followUpRegex.hasMatch(line)) {
      followUpDate = followUpRegex.firstMatch(line)!.group(1) ?? "";
    }

    // Extract Instructions
    if (line.toLowerCase().contains("advice") || line.toLowerCase().contains("instructions")) {
      instructions = line.split(":").last.trim();
    }

    // Extract Medicine Names
    if (line.startsWith("TAB.") || line.startsWith("CAP.")) {
      medicineNames.add(line.replaceFirst(RegExp(r"(TAB\.|CAP\.)\s*"), "").trim());
    }

    // Extract Dosages
    else if (dosageRegex.hasMatch(line)) {
      dosages.add(line);
    }

    // Extract Durations
    else if (durationRegex.hasMatch(line)) {
      durations.add(line);
    }
  }

  // Link medications with their dosage and duration
  for (int i = 0; i < medicineNames.length; i++) {
    medications.add({
      "name": medicineNames[i],
      "dosage": i < dosages.length ? dosages[i] : "",
      "duration": i < durations.length ? durations[i] : "",
    });
  }

  return {
    "doctor_name": doctorName,
    "contact": contact,
    "diagnosis": diagnosis,
    "follow_up_date": followUpDate,
    "instructions": instructions,
    "medications": medications,
  };
  }

  /// 📌 Save Data (Check-Up or Medical)
Future<void> saveData(File image, BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  String extractedText = await extractText(image);
  String base64Image = await convertImageToBase64(image);
  String userEmail = user.email ?? "unknown_user";

  bool isCheckup = isCheckupRecord(extractedText);

  if (isCheckup) {
    // 🔹 Extract Check-Up Data
    Map<String, dynamic> checkupData = extractCheckupDetails(extractedText);
    checkupData['imageBase64'] = base64Image;
    checkupData['email'] = userEmail;
    checkupData['timestamp'] = Timestamp.now();

    // 🔹 Ask User for Next Check-Up Date
    DateTime? nextCheckup = await askUserForNextCheckupDate(context);
    if (nextCheckup != null) {
      checkupData['next_checkup_date'] = nextCheckup.toIso8601String();
      NotificationService.scheduleNotification(
        500,  // Unique ID for check-up reminder
        "Check-Up Reminder",
        "You scheduled a check-up on ${DateFormat("dd MMM yyyy").format(nextCheckup)}",
        nextCheckup,
      );
    }

    // 🔹 Store as a New Document in `checkup_records` Collection
    await FirebaseFirestore.instance.collection('checkup_records').add(checkupData);
  } else {
    // 🔹 Extract Medical Record Data
    Map<String, dynamic> medicalData = extractMedicalRecord(extractedText);
    medicalData['imageBase64'] = base64Image;
    medicalData['email'] = userEmail;
    medicalData['timestamp'] = Timestamp.now();

    // 🔹 Store as a New Document in `medical_records` Collection
    await FirebaseFirestore.instance.collection('medical_records').add(medicalData);

    // 🔹 Schedule Medication Reminders
    List medications = medicalData["medications"];
    for (var med in medications) {
      DateTime reminderTime = DateTime.now().add(Duration(hours: 1)); // Example: 1 hour later
      NotificationService.scheduleNotification(
        medications.indexOf(med),
        "Time to take ${med["name"]}",
        "Dosage: ${med["dosage"]}",
        reminderTime,
      );
    }

    // 🔹 If you still need `setReminders(medicalData)`, make sure it doesn’t duplicate notifications.
    setReminders(medicalData);
  }
}

void setReminders(Map<String, dynamic> extractedData) {
  List<Map<String, String>> medications = List<Map<String, String>>.from(extractedData['medications']);
  DateTime now = DateTime.now();

  for (var med in medications) {
    String medName = med['name'] ?? "Unknown Medicine";
    String dosage = med['dosage'] ?? "";
    String durationStr = med['duration'] ?? "1 Days";
    
    int durationDays = int.tryParse(RegExp(r"\d+").firstMatch(durationStr)?.group(0) ?? "1") ?? 1;

    for (int i = 0; i < durationDays; i++) {
      DateTime reminderTime = now.add(Duration(days: i, hours: 9)); // Morning 9 AM

      int uniqueId = medName.hashCode + i; // ✅ Unique ID based on name + day
      NotificationService.scheduleNotification(
        uniqueId,
        "Time to take $medName",
        "Dosage: $dosage",
        reminderTime,
      );
    }
  }
}


  /// 📌 Ask User to Choose Next Check-Up Date
Future<DateTime?> askUserForNextCheckupDate(BuildContext context) async {
  DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 365)), // Limit to 1 year
  );
  return selectedDate;
}

  DateTime? parseDate(String dateStr) {
    try {
      return DateFormat("dd-MM-yyyy").parse(dateStr);
    } catch (e) {
      print("❌ Invalid date format: $dateStr");
      return null;
    }
  }
 void _scheduleDailyReminder(int id, String medName, String dosage, DateTime startTime, int days) {
  for (int i = 0; i < days; i++) {
    DateTime reminderTime = startTime.add(Duration(days: i));
    
    if (reminderTime.isAfter(DateTime.now())) {
      print("⏰ Scheduling Reminder: Take $medName - $dosage at ${DateFormat("hh:mm a").format(reminderTime)}");
      
      NotificationService.scheduleNotification(
        id + i,  // Unique ID for each reminder
        "Time to take $medName",
        "Dosage: $dosage",
        reminderTime,
      );
    }
  }
}
}
