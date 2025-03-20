/* 
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OCRService {
  final ImagePicker _picker = ImagePicker();

  // 📌 Pick Image from Camera or Gallery
  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // 📌 Perform Text Recognition (OCR)
  Future<String> extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  // 📌 Convert Image to Base64
  Future<String> convertImageToBase64(File image) async {
    List<int> imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);
  }

  // 📌 Extract Structured Data (Doctor, Medications, Duration, Follow-Up)
  Map<String, dynamic> extractMedicalDetails(String text) {
    String doctorName = "";
    String contact = "";
    String diagnosis = "";
    String instructions = "";
    String followUpDate = "";
    List<Map<String, String>> medications = [];
    
    // 🔹 Regex Patterns
    RegExp doctorPattern = RegExp(r"Dr\.\s+[A-Za-z\s]+");
    RegExp contactPattern = RegExp(r"Mob\. No:\s*(\d+)|Ph:\s*(\d+)");
    RegExp diagnosisPattern = RegExp(r"Diagnosis:\s*(.+)");
    RegExp instructionsPattern = RegExp(r"Instructions:\s*(.+)");
    RegExp followUpPattern = RegExp(r"Follow Up:\s*(\d{2}-\d{2}-\d{4})");
    RegExp medPattern = RegExp(r"\d+\)\s*([\w\s\.]+)\s*\|\s*([\w\s,]+)\s*\|\s*([\w\s\d\(\)]+)");

    // 🔹 Extract Data
    doctorName = doctorPattern.firstMatch(text)?.group(0) ?? "Unknown Doctor";
    contact = contactPattern.firstMatch(text)?.group(1) ?? "No Contact Info";
    diagnosis = diagnosisPattern.firstMatch(text)?.group(1) ?? "No Diagnosis";
    instructions = instructionsPattern.firstMatch(text)?.group(1) ?? "No Instructions";
    followUpDate = followUpPattern.firstMatch(text)?.group(1) ?? "No Follow-Up Date";

    // 🔹 Extract Medications
    for (RegExpMatch match in medPattern.allMatches(text)) {
      medications.add({
        "name": match.group(1) ?? "Unknown Medicine",
        "dosage": match.group(2) ?? "No Dosage Info",
        "duration": match.group(3) ?? "No Duration Info"
      });
    }

    return {
      "doctor_name": doctorName,
      "contact": contact,
      "diagnosis": diagnosis,
      "instructions": instructions,
      "follow_up_date": followUpDate,
      "medications": medications
    };
  }

  // 📌 Save Extracted Data to Firestore
  Future<void> saveExtractedData(Map<String, dynamic> extractedData, String base64Image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No user logged in.");

    // 🔹 Add image and timestamp
    extractedData['imageBase64'] = base64Image;
    extractedData['timestamp'] = Timestamp.now();

    // 🔹 Firestore Reference
    String userEmail = user.email ?? "unknown_user";
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('medical_records').doc(userEmail);
    DocumentSnapshot userDoc = await userDocRef.get();

    if (userDoc.exists && userDoc.data() != null) {
      await userDocRef.update({
        'medical_data': FieldValue.arrayUnion([extractedData])
      });
      print("✅ Medical record updated.");
    } else {
      await userDocRef.set({
        'email': userEmail,
        'medical_data': [extractedData]
      });
      print("✅ New medical record created.");
    }
  }
}
 */
/* 
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OCRService {
  final ImagePicker _picker = ImagePicker();

  // 📌 Pick Image from Camera or Gallery
  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // 📌 Perform Text Recognition (OCR)
  Future<String> extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  // 📌 Convert Image to Base64
  Future<String> convertImageToBase64(File image) async {
    List<int> imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);
  }

  // 📌 Extract Structured Data (Doctor, Medications, Diagnosis, Follow-Up)
  Map<String, dynamic> extractMedicalDetails(String text) {
    String doctorName = "Unknown Doctor";
    String contact = "No Contact Info";
    String diagnosis = "No Diagnosis";
    String instructions = "No Instructions";
    String followUpDate = "No Follow-Up Date";
    List<Map<String, String>> medications = [];

    // 🔹 Split into lines for easier processing
    List<String> lines = text.split("\n");

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // 🔹 Extract Doctor Name
      if (line.toLowerCase().startsWith("dr.") && doctorName == "Unknown Doctor") {
        doctorName = line;
      }

      // 🔹 Extract Contact Info
      if (line.toLowerCase().contains("mob") || line.toLowerCase().contains("ph")) {
        contact = line.replaceAll(RegExp(r"[^0-9+]"), ''); // Keep only numbers
      }

      // 🔹 Extract Diagnosis
      if (line.toLowerCase().contains("diagnosis:")) {
        diagnosis = line.split(":").last.trim();
      }

      // 🔹 Extract Follow-Up Date
      RegExp followUpPattern = RegExp(r"Follow Up:\s*(\d{2}-\d{2}-\d{4})");
      if (followUpPattern.hasMatch(line)) {
        followUpDate = followUpPattern.firstMatch(line)?.group(1) ?? "No Follow-Up Date";
      }

      // 🔹 Extract Instructions
      if (line.toLowerCase().contains("instructions:") || line.toLowerCase().contains("advice given:")) {
        instructions = line.split(":").last.trim();
      }

      // 🔹 Extract Medications (Format: Medicine | Dosage | Duration)
      RegExp medPattern = RegExp(r"(\d+\))?\s*([\w\s\.]+)\s*\|\s*([\w\s,]+)\s*\|\s*([\w\s\d\(\)]+)");
      if (medPattern.hasMatch(line)) {
        var match = medPattern.firstMatch(line);
        medications.add({
          "name": match?.group(2)?.trim() ?? "Unknown Medicine",
          "dosage": match?.group(3)?.trim() ?? "No Dosage Info",
          "duration": match?.group(4)?.trim() ?? "No Duration Info"
        });
      }
    }

    return {
      "doctor_name": doctorName,
      "contact": contact,
      "diagnosis": diagnosis,
      "instructions": instructions,
      "follow_up_date": followUpDate,
      "medications": medications
    };
  }

  // 📌 Save Extracted Data to Firestore
  Future<void> saveExtractedData(Map<String, dynamic> extractedData, String base64Image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No user logged in.");

    // 🔹 Add image and timestamp
    extractedData['imageBase64'] = base64Image;
    extractedData['timestamp'] = Timestamp.now();

    // 🔹 Firestore Reference
    String userEmail = user.email ?? "unknown_user";
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('medical_records').doc(userEmail);
    DocumentSnapshot userDoc = await userDocRef.get();

    if (userDoc.exists && userDoc.data() != null) {
      await userDocRef.update({
        'medical_data': FieldValue.arrayUnion([extractedData])
      });
      print("✅ Medical record updated.");
    } else {
      await userDocRef.set({
        'email': userEmail,
        'medical_data': [extractedData]
      });
      print("✅ New medical record created.");
    }
  }
}
 */
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';

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
}



class OCRService {
  final ImagePicker _picker = ImagePicker();

  // 📌 Pick Image from Camera or Gallery
  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // 📌 Perform Text Recognition (OCR)
/*    Future<String> extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }  */
 Future<String> extractText(File image) async {
  final inputImage = InputImage.fromFile(image);
  final textRecognizer = TextRecognizer();
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  await textRecognizer.close();

  print("🔍 Full OCR Extracted Text:\n${recognizedText.text}"); // Debugging Output
  return recognizedText.text;
}


  // 📌 Convert Image to Base64
  Future<String> convertImageToBase64(File image) async {
    List<int> imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);
  }

  // 📌 Extract Structured Data
 Map<String, dynamic> extractMedicalDetails(String text) {
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
    RegExp followUpRegex = RegExp(r"Follow\s*Up:\s*(\d{1,2}[-/]\d{1,2}[-/]\d{4})", caseSensitive: false);
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

  // 📌 Save Extracted Data & Base64 Image to Firestore
  Future<void> saveExtractedData(Map<String, dynamic> extractedData, String base64Image) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("No user logged in.");
  }

  extractedData['imageBase64'] = base64Image;
  extractedData['timestamp'] = Timestamp.now();
  


  String userEmail = user.email ?? "unknown_user";
  DocumentReference userDocRef = FirebaseFirestore.instance.collection('medical_records').doc(userEmail);

  DocumentSnapshot userDoc = await userDocRef.get();

  if (userDoc.exists && userDoc.data() != null) {
    await userDocRef.update({
      'medical_data': FieldValue.arrayUnion([extractedData])
    });
  } else {
    await userDocRef.set({
      'email': userEmail,
      'medical_data': [extractedData]
    });
  }

  // 🔔 Schedule Medication Reminders
  List medications = extractedData["medications"];
  for (var med in medications) {
    DateTime reminderTime = DateTime.now().add(Duration(hours: 1)); // Example: 1 hour later
    NotificationService.scheduleNotification(
      medications.indexOf(med),
      "Time to take ${med["name"]}",
      "Dosage: ${med["dosage"]}",
      reminderTime,
    );
  }
  DateTime? followUpDate = parseFollowUpDate(extractedData["follow_up_date"]);
  if (followUpDate != null) {
    NotificationService.scheduleNotification(
      999,  // Unique ID for follow-up notification
      "Doctor Follow-Up Reminder",
      "You have a follow-up appointment on ${DateFormat("dd MMM yyyy").format(followUpDate)}",
      followUpDate,
    );
  }
  sendTestNotification();
  setReminders(extractedData);
}
  // 📌 Set Reminders for Medications & Doctor Visits
void setReminders(Map<String, dynamic> extractedData) {
  List<Map<String, String>> medications = List<Map<String, String>>.from(extractedData['medications']);

  DateTime now = DateTime.now();
  
  for (var med in medications) {
    String medName = med['name'] ?? "Unknown Medicine";
    String dosage = med['dosage'] ?? "";
    String durationStr = med['duration'] ?? "1 Days"; // Default duration if missing

    int durationDays = int.tryParse(RegExp(r"\d+").firstMatch(durationStr)?.group(0) ?? "1") ?? 1; 

    // Check if dosage contains 'Morning' or 'Night'
    if (dosage.toLowerCase().contains("morning")) {
      DateTime morningTime = DateTime(now.year, now.month, now.day, 9, 0); // 9:00 AM
      _scheduleDailyReminder(medications.indexOf(med), medName, dosage, morningTime, durationDays);
    }

    if (dosage.toLowerCase().contains("night")) {
      DateTime nightTime = DateTime(now.year, now.month, now.day, 21, 0); // 9:00 PM
      _scheduleDailyReminder(medications.indexOf(med) + 100, medName, dosage, nightTime, durationDays);
    }
  }

  // 🔹 Schedule Follow-Up Reminder
  if (extractedData['follow_up_date'].isNotEmpty) {
    DateTime? followUpDate = parseFollowUpDate(extractedData["follow_up_date"]);
    if (followUpDate != null) {
      print("📅 Scheduling Follow-Up Reminder for ${DateFormat("dd MMM yyyy").format(followUpDate)}");
      NotificationService.scheduleNotification(
        999, // Unique ID for follow-up
        "Doctor Follow-Up Reminder",
        "Your appointment is on ${DateFormat("dd MMM yyyy").format(followUpDate)}",
        followUpDate,
      );
    } else {
      print("⚠️ Invalid Follow-Up Date: ${extractedData['follow_up_date']}");
    }
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


  // 📌 Test Notification Function
  void sendTestNotification() {
    NotificationService.scheduleNotification(
      0,
      "Test Reminder",
      "This is a test notification",
      DateTime.now().add(Duration(seconds: 15)),
    );
    print("✅ Test notification scheduled!");
  }
}