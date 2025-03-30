import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MentalHealthAssessmentWidget extends StatefulWidget {
  const MentalHealthAssessmentWidget({super.key});

  @override
  _MentalHealthAssessmentWidgetState createState() => _MentalHealthAssessmentWidgetState();
}

class _MentalHealthAssessmentWidgetState extends State<MentalHealthAssessmentWidget> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String userEmail = FirebaseAuth.instance.currentUser?.email ?? "";
   String? _riskLevel;
  List<Map<String, String>> _recommendations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    assessMentalHealthRisk();
  }


  Future<void> assessMentalHealthRisk() async {
    if (userEmail.isEmpty) {
      setState(() {
        _errorMessage = "User not logged in";
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch last 7 journal entries
      QuerySnapshot journalSnapshot = await firestore
          .collection('journals')
          .where('user_email', isEqualTo: userEmail)
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      if (journalSnapshot.docs.isEmpty) {
         setState(() {
          _riskLevel = "No Data";
          _recommendations = [];
          _isLoading = false;
        });
        return;
      
      }

      // Define score mapping fields
      List<String> fields = [
        "mood",
        "social_interaction",
        "work_productivity",
        "hobbies_selfcare",
        "emotional_triggers",
        "sleep_quality",
        "appetite"
      ];

      int totalScore = 0;
      /* Map<String, int> fieldScores = {for (var field in fields) field: 0};

      // Calculate total score and individual category scores
      for (var doc in journalSnapshot.docs) {
        Map<String, dynamic> entry = doc.data() as Map<String, dynamic>;
        print("Journal Entry: $entry");
        for (var field in fields) {
          if (entry.containsKey(field)) {
            print("Field: $field, Value: ${entry[field]}, Type: ${entry[field].runtimeType}");
            fieldScores[field] = (fieldScores[field] ?? 0) + (entry[field] as int);
          }
        }
      }

      if (fieldScores.isNotEmpty) {
        totalScore = fieldScores.values.fold(0, (a, b) => a + b);
      }
      // Determine risk level
      String riskLevel;
       Color riskColor;
      if (totalScore <= 6) {
        riskLevel = "You're doing great! 🌿";
        riskColor = Colors.green.shade400;
      } else if (totalScore <= 14) {
        riskLevel = "Hang in there! ☀️";
        riskColor = Colors.orange.shade400;
      } else {
        riskLevel = "Self-care time ❤️";
        riskColor = Colors.red.shade400;
      } */
     // Step 1: Organize entries by date
Map<String, Map<String, int>> dailyScores = {};
Set<String> uniqueDates = {}; 

for (var doc in journalSnapshot.docs) {
  Map<String, dynamic> entry = doc.data() as Map<String, dynamic>;
  String date = (entry["date"] as Timestamp).toDate().toString().split(" ")[0]; // Extract YYYY-MM-DD

  uniqueDates.add(date); // Track unique dates

  if (!dailyScores.containsKey(date)) {
    dailyScores[date] = {for (var field in fields) field: 0};
  }

  for (var field in fields) {
    if (entry.containsKey(field)) {
      dailyScores[date]![field] = (dailyScores[date]![field] ?? 0) + (entry[field] as int);
    }
  }
}

// Step 2: Compute daily averages
// Step 2: Compute daily averages (Corrected)
int totalDays = uniqueDates.length;
Map<String, double> averagedScores = {for (var field in fields) field: 0.0};

for (var date in dailyScores.keys) {
  for (var field in fields) {
    averagedScores[field] = (averagedScores[field]! + dailyScores[date]![field]!); // Just summing up first
  }
}

// Divide once after summing
for (var field in fields) {
  averagedScores[field] = averagedScores[field]! / totalDays;
}

// Step 3: Compute final total score based on daily averages
double totalAverageScore = averagedScores.values.fold(0.0, (a, b) => a + b);

// Step 4: Adjust risk level calculation based on daily average score
String riskLevel;
Color riskColor;
print(totalAverageScore);
if (totalAverageScore <= 1.0) {
  riskLevel = "You're doing great! 🌿";
  riskColor = Colors.green.shade400;
} else if (totalAverageScore <= 2.5) {
  riskLevel = "Hang in there! ☀️";
  riskColor = Colors.orange.shade400;
} else {
  riskLevel = "Self-care time ❤️";
  riskColor = Colors.red.shade400;
}


      // Fetch user's hobbies, self-care activities, and close contacts
     QuerySnapshot userSnapshot = await firestore
    .collection('users')
    .where('email', isEqualTo: userEmail)
    .limit(1)
    .get();

if (userSnapshot.docs.isEmpty) {
  setState(() {
    _errorMessage = "User profile not found in Firestore.";
    _isLoading = false;
  });
  return;
}

// Get the first document
DocumentSnapshot userDoc = userSnapshot.docs.first;

      List<String> hobbies = List<String>.from(userDoc["hobbies"] ?? []);
      List<String> selfCare = List<String>.from(userDoc["self_care_activities"] ?? []);
      List<String> closeContacts =
          List<String>.from(userDoc["close_contacts"] ?? []);

       // **Mood Trend Analysis (Detecting Consecutive Low Moods)**
  int consecutiveLowMoods = 0;
  for (var doc in journalSnapshot.docs) {
    if ((doc.data() as Map<String, dynamic>)["mood"] is int &&
            (doc.data() as Map<String, dynamic>)["mood"] >= 2) {
          consecutiveLowMoods++;
        } else {
          break;
        }
      }
      // Generate personalized recommendations
      // Generate personalized recommendations
List<Map<String, String>> recommendations = [];

// Social interaction recommendation
if ((averagedScores["social_interaction"] ?? 0) <= 1.5) {  // Adjusted for average
  recommendations.add({
    "icon": "🤗",
    "text":
        "Try socializing with family or friends. Even small interactions can uplift your mood!"
  });
}

// Hobbies & self-care recommendation
if ((averagedScores["hobbies_selfcare"] ?? 0) <= 1.5 && hobbies.isNotEmpty) {  // Adjusted for average
  recommendations.add({
    "icon": "🎨",
    "text":
        "It's been a while since you engaged in ""${hobbies.join(", ")}"". Try making time for them!"
  });
}

// Sleep quality recommendation
if ((averagedScores["sleep_quality"] ?? 0) >= 2.5) {  // Adjusted for average
  recommendations.add({
    "icon": "😴",
    "text":
        "Your sleep quality seems low. Try reducing screen time, drinking herbal tea, or relaxation techniques."
  });
}

// Emotional support recommendation
if (totalAverageScore >= 6.0 && closeContacts.isNotEmpty) {  // Adjusted for total avg
  recommendations.add({
    "icon": "💙",
    "text":
        "Consider reaching out to ""${closeContacts.first}"" for support. Talking to a trusted person can help!"
  });
}

// Consecutive low moods recommendation
if (consecutiveLowMoods >= 3) {
  recommendations.add({
    "icon": "📝",
    "text":
        "You've been feeling down for the last few days. Consider journaling your thoughts or reaching out for professional guidance."
  });
}


    setState(() {
        _riskLevel = riskLevel;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to assess risk: $e";
        _isLoading = false;
      });
    }
  }
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mental Health Assessment"),
      backgroundColor:Color.fromARGB(255, 61, 93, 74),
      foregroundColor: const Color.fromARGB(255, 241, 250, 245),),
      body: _isLoading
      ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
      /* future: assessMentalHealthRisk(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.containsKey("error")) {
          return Center(child: Text(snapshot.data?["error"] ?? "Error fetching data"));
        }

        String riskLevel = snapshot.data!["riskLevel"];
        List<Map<String, String>> recommendations = snapshot.data!["recommendations"];

        return */ :Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: _riskLevel == "No Data"
                            ? Colors.grey.shade300
                            : _riskLevel!.contains("Low Risk")
                                ? Colors.green.shade100
                                : _riskLevel!.contains("Moderate Risk")
                                    ? Colors.orange.shade100
                                    : Colors.red.shade100,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                "Mental Health Risk Level",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _riskLevel!,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                             ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Personalized Recommendations",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      ..._recommendations.map((rec) {
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            leading: Text(rec["icon"] ?? "💡", style: const TextStyle(fontSize: 24)),
                            title: Text(rec["text"] ?? ""),
                          ),
                        );
                      }).toList(),
            ],
          ),
        ),
      
    );
  }

}
 
